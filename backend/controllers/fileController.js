const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { eq, like, and, desc, asc, sql } = require('drizzle-orm');
const db = require('../db');
const { users, files, photoMetadata } = require('../db/schema');
const fileStorage = require('../utils/fileStorage');

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const userId = String(req.user.id); // Ensure userId is a string
    const userDir = path.join(__dirname, '..', 'uploads', userId);
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }
    
    cb(null, userDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename
    const uniqueFilename = `${Date.now()}_${uuidv4()}_${file.originalname}`;
    cb(null, uniqueFilename);
  }
});

// Configure file upload
const upload = multer({ 
  storage: storage,
  limits: { fileSize: 100 * 1024 * 1024 } // 100MB max file size
});

// Upload middleware
exports.uploadMiddleware = upload.single('file');

// Batch upload middleware (for iCloud-like sync)
exports.batchUploadMiddleware = upload.array('files', 20); // Allow up to 20 files at once

// Upload file
exports.uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const userId = req.user.id;
    const { type = 'other' } = req.body;
    
    // Get file info
    const fileSize = req.file.size;
    const originalName = req.file.originalname;
    const filePath = req.file.path;
    const relativePath = path.relative(path.join(__dirname, '..'), filePath);
    
    // Check user storage limit
    const userResults = await db.select().from(users).where(eq(users.id, userId));
    
    if (userResults.length === 0) {
      // Delete file if user not found
      fs.unlink(filePath, (err) => {
        if (err) console.error('Error deleting file:', err);
      });
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResults[0];
    
    if (user.storageUsed + fileSize > user.storageLimit) {
      // Delete file if storage limit exceeded
      fs.unlink(filePath, (err) => {
        if (err) console.error('Error deleting file:', err);
      });
      return res.status(400).json({ message: 'Storage limit exceeded' });
    }
    
    // Generate thumbnail for images
    let thumbnailPath = null;
    if (type === 'image') {
      try {
        thumbnailPath = await fileStorage.generateThumbnail(filePath, userId);
      } catch (err) {
        console.error('Error generating thumbnail:', err);
      }
    }
    
    // Create file record in database
    const [insertedFile] = await db.insert(files).values({
      userId: userId,
      originalName: originalName,
      fileName: path.basename(filePath),
      filePath: relativePath,
      thumbnailPath: thumbnailPath,
      fileType: type,
      fileSize: fileSize,
      isPublic: false
    }).returning();
    
    // Extract and store metadata for image files
    if (type === 'image') {
      try {
        // Extract metadata using the utility function
        const metadata = await fileStorage.extractImageMetadata(filePath);
        
        // Store metadata in the photo_metadata table
        await db.insert(photoMetadata).values({
          fileId: insertedFile.id,
          dateTaken: metadata.dateTaken || insertedFile.createdAt,
          latitude: metadata.location ? metadata.location.latitude : null,
          longitude: metadata.location ? metadata.location.longitude : null,
          cameraModel: metadata.camera,
          resolution: metadata.resolution,
          organized: false
        });
      } catch (metadataError) {
        console.error('Error extracting or storing image metadata:', metadataError);
        // Continue without metadata if extraction fails
      }
    }
    
    // Update user storage used
    await db.update(users)
      .set({ storageUsed: user.storageUsed + fileSize })
      .where(eq(users.id, userId));
    
    res.status(201).json({
      id: insertedFile.id,
      name: insertedFile.originalName,
      size: insertedFile.fileSize,
      type: insertedFile.fileType,
      path: insertedFile.filePath,
      createdAt: insertedFile.createdAt,
      updatedAt: insertedFile.updatedAt,
      userId: insertedFile.userId,
      isUploaded: true,
      thumbnailUrl: insertedFile.thumbnailPath
    });
  } catch (error) {
    console.error('Upload file error:', error);
    res.status(500).json({ message: 'Server error during file upload' });
  }
};

// Get all files for user
exports.getFiles = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const fileResults = await db.select().from(files).where(eq(files.userId, userId));
    
    const formattedFiles = fileResults.map(file => ({
      id: file.id,
      name: file.originalName,
      size: file.fileSize,
      type: file.fileType,
      path: file.filePath,
      createdAt: file.createdAt,
      updatedAt: file.updatedAt,
      userId: file.userId,
      isUploaded: true,
      thumbnailUrl: file.thumbnailPath
    }));
    
    res.status(200).json(formattedFiles);
  } catch (error) {
    console.error('Get files error:', error);
    res.status(500).json({ message: 'Server error retrieving files' });
  }
};

// Get file by ID
exports.getFileById = async (req, res) => {
  try {
    const fileId = req.params.id;
    const userId = req.user.id;
    
    const fileResults = await db.select()
      .from(files)
      .where(
        eq(files.id, fileId),
        eq(files.userId, userId)
      );
    
    if (fileResults.length === 0) {
      return res.status(404).json({ message: 'File not found' });
    }
    
    const file = fileResults[0];
    
    res.status(200).json({
      id: file.id,
      name: file.originalName,
      size: file.fileSize,
      type: file.fileType,
      path: file.filePath,
      createdAt: file.createdAt,
      updatedAt: file.updatedAt,
      userId: file.userId,
      isUploaded: true,
      thumbnailUrl: file.thumbnailPath
    });
  } catch (error) {
    console.error('Get file error:', error);
    res.status(500).json({ message: 'Server error retrieving file' });
  }
};

// Download file
exports.downloadFile = async (req, res) => {
  try {
    const fileId = req.params.id;
    const userId = req.user.id;
    
    const fileResults = await db.select()
      .from(files)
      .where(
        eq(files.id, fileId),
        eq(files.userId, userId)
      );
    
    if (fileResults.length === 0) {
      return res.status(404).json({ message: 'File not found' });
    }
    
    const file = fileResults[0];
    const filePath = path.join(__dirname, '..', file.filePath);
    
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: 'File not found on server' });
    }
    
    // Set Content-Disposition header to force download
    res.setHeader('Content-Disposition', `attachment; filename="${file.originalName}"`);
    
    // Send file
    res.sendFile(filePath);
  } catch (error) {
    console.error('Download file error:', error);
    res.status(500).json({ message: 'Server error downloading file' });
  }
};

// Delete file
exports.deleteFile = async (req, res) => {
  try {
    const fileId = req.params.id;
    const userId = req.user.id;
    
    const fileResults = await db.select()
      .from(files)
      .where(
        eq(files.id, fileId),
        eq(files.userId, userId)
      );
    
    if (fileResults.length === 0) {
      return res.status(404).json({ message: 'File not found' });
    }
    
    const file = fileResults[0];
    const filePath = path.join(__dirname, '..', file.filePath);
    
    // Delete file from storage
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    
    // Delete thumbnail if exists
    if (file.thumbnailPath) {
      const thumbnailPath = path.join(__dirname, '..', file.thumbnailPath);
      if (fs.existsSync(thumbnailPath)) {
        fs.unlinkSync(thumbnailPath);
      }
    }
    
    // Get user to update storage used
    const userResults = await db.select().from(users).where(eq(users.id, userId));
    
    if (userResults.length > 0) {
      const user = userResults[0];
      const newStorageUsed = Math.max(0, user.storageUsed - file.fileSize);
      
      // Update user storage used
      await db.update(users)
        .set({ storageUsed: newStorageUsed })
        .where(eq(users.id, userId));
    }
    
    // Remove file record from database
    await db.delete(files)
      .where(
        eq(files.id, fileId),
        eq(files.userId, userId)
      );
    
    res.status(200).json({ message: 'File deleted successfully' });
  } catch (error) {
    console.error('Delete file error:', error);
    res.status(500).json({ message: 'Server error deleting file' });
  }
};

// Get file types summary (count and size by type)
exports.getFileTypeSummary = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Use Drizzle's SQL builder instead of raw SQL
    const fileSummary = await db.execute(sql`
      SELECT 
        file_type as type, 
        COUNT(*) as count, 
        SUM(file_size) as "totalSize"
      FROM files 
      WHERE user_id = ${userId}
      GROUP BY file_type
    `);
    
    // Return only the rows data
    res.status(200).json(fileSummary.rows);
  } catch (error) {
    console.error('Get file type summary error:', error);
    res.status(500).json({ message: 'Server error retrieving file summary' });
  }
};

// Batch Upload Files (iCloud-like sync)
exports.batchUploadFiles = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No files uploaded' });
    }

    const userId = req.user.id;
    const { autoOrganize = 'false' } = req.body;
    
    // Get user info to check storage limits
    const userResults = await db.select().from(users).where(eq(users.id, userId));
    
    if (userResults.length === 0) {
      // Delete files if user not found
      req.files.forEach(file => {
        fs.unlink(file.path, err => {
          if (err) console.error(`Error deleting file ${file.path}:`, err);
        });
      });
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResults[0];
    
    // Calculate total size of uploaded files
    const totalUploadSize = req.files.reduce((sum, file) => sum + file.size, 0);
    
    // Check if total size exceeds user's storage limit
    if (user.storageUsed + totalUploadSize > user.storageLimit) {
      // Delete all files if storage limit would be exceeded
      req.files.forEach(file => {
        fs.unlink(file.path, err => {
          if (err) console.error(`Error deleting file ${file.path}:`, err);
        });
      });
      return res.status(400).json({ message: 'Storage limit exceeded' });
    }
    
    // Process each file
    const uploadedFiles = [];
    let totalProcessedSize = 0;
    
    for (const file of req.files) {
      try {
        // Determine file type based on extension
        const ext = path.extname(file.originalname).toLowerCase();
        let fileType = 'other';
        
        if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'].includes(ext)) {
          fileType = 'image';
        } else if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.mkv'].includes(ext)) {
          fileType = 'video';
        } else if (['.mp3', '.wav', '.ogg', '.m4a', '.flac'].includes(ext)) {
          fileType = 'audio';
        } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].includes(ext)) {
          fileType = 'document';
        }
        
        // Generate thumbnail for images
        let thumbnailPath = null;
        if (fileType === 'image') {
          try {
            thumbnailPath = await fileStorage.generateThumbnail(file.path, userId);
          } catch (err) {
            console.error(`Error generating thumbnail for ${file.originalname}:`, err);
          }
        }
        
        // Get relative path for storage
        const relativePath = path.relative(path.join(__dirname, '..'), file.path);
        
        // Insert file record into database
        const [insertedFile] = await db.insert(files).values({
          userId: userId,
          originalName: file.originalname,
          fileName: path.basename(file.path),
          filePath: relativePath,
          thumbnailPath: thumbnailPath,
          fileType: fileType,
          fileSize: file.size,
          isPublic: false
        }).returning();
        
        // Extract and store metadata for image files
        if (fileType === 'image') {
          try {
            // Extract metadata using the utility function
            const metadata = await fileStorage.extractImageMetadata(file.path);
            
            // Store metadata in the photo_metadata table
            await db.insert(photoMetadata).values({
              fileId: insertedFile.id,
              dateTaken: metadata.dateTaken || insertedFile.createdAt,
              latitude: metadata.location ? metadata.location.latitude : null,
              longitude: metadata.location ? metadata.location.longitude : null,
              cameraModel: metadata.camera,
              resolution: metadata.resolution,
              organized: false
            });
          } catch (metadataError) {
            console.error(`Error extracting or storing metadata for ${file.originalname}:`, metadataError);
            // Continue without metadata if extraction fails
          }
        }
        
        totalProcessedSize += file.size;
        
        uploadedFiles.push({
          id: insertedFile.id,
          name: insertedFile.originalName,
          size: insertedFile.fileSize,
          type: insertedFile.fileType,
          path: insertedFile.filePath,
          createdAt: insertedFile.createdAt,
          updatedAt: insertedFile.updatedAt,
          userId: insertedFile.userId,
          isUploaded: true,
          thumbnailUrl: insertedFile.thumbnailPath
        });
      } catch (fileError) {
        console.error(`Error processing file ${file.originalname}:`, fileError);
        // Continue with next file even if one fails
      }
    }
    
    // Update user's storage used
    await db.update(users)
      .set({ storageUsed: user.storageUsed + totalProcessedSize })
      .where(eq(users.id, userId));
    
    // Auto-organize photos if requested
    if (autoOrganize === 'true') {
      // Run photo organization in the background
      fileStorage.organizePhotosByDate(userId)
        .then(organizeResult => {
          console.log(`Auto-organized photos for user ${userId}:`, organizeResult);
        })
        .catch(err => {
          console.error(`Error auto-organizing photos for user ${userId}:`, err);
        });
    }
    
    res.status(201).json({
      message: `Successfully uploaded ${uploadedFiles.length} files`,
      files: uploadedFiles,
      failedCount: req.files.length - uploadedFiles.length
    });
  } catch (error) {
    console.error('Batch upload error:', error);
    res.status(500).json({ message: 'Server error during batch file upload' });
  }
};

// Get photos organized by date (like iCloud Photos)
exports.getPhotosByDate = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Query for image files
    const imageFiles = await db.select()
      .from(files)
      .where(and(
        eq(files.userId, userId),
        eq(files.fileType, 'image')
      ))
      .orderBy(desc(files.createdAt));
    
    // Group photos by date
    const photosByDate = {};
    
    for (const file of imageFiles) {
      const createdAt = new Date(file.createdAt);
      const dateKey = createdAt.toISOString().split('T')[0]; // YYYY-MM-DD
      
      if (!photosByDate[dateKey]) {
        photosByDate[dateKey] = {
          date: dateKey,
          dateFormatted: createdAt.toLocaleDateString('en-US', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
          }),
          photos: []
        };
      }
      
      photosByDate[dateKey].photos.push({
        id: file.id,
        name: file.originalName,
        size: file.fileSize,
        path: file.filePath,
        thumbnailUrl: file.thumbnailPath,
        createdAt: file.createdAt
      });
    }
    
    // Convert to array and sort by date (newest first)
    const response = Object.values(photosByDate).sort((a, b) => {
      return new Date(b.date) - new Date(a.date);
    });
    
    res.status(200).json(response);
  } catch (error) {
    console.error('Get photos by date error:', error);
    res.status(500).json({ message: 'Server error retrieving photos' });
  }
};

// Get optimized thumbnail gallery
exports.getPhotoGallery = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;
    
    // Query for image files with pagination
    const imageFiles = await db.select()
      .from(files)
      .where(and(
        eq(files.userId, userId),
        eq(files.fileType, 'image')
      ))
      .orderBy(desc(files.createdAt))
      .limit(parseInt(limit))
      .offset(parseInt(offset));
    
    // Get total count for pagination using the SQL tag
    const countResult = await db.execute(sql`
      SELECT COUNT(*) as count
      FROM files
      WHERE user_id = ${userId} AND file_type = 'image'
    `);
    const totalCount = parseInt(countResult.rows[0]?.count || 0);
    
    const gallery = imageFiles.map(file => ({
      id: file.id,
      thumbnailUrl: file.thumbnailPath,
      originalUrl: file.filePath,
      name: file.originalName,
      createdAt: file.createdAt
    }));
    
    res.status(200).json({
      gallery,
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: parseInt(offset) + gallery.length < totalCount
      }
    });
  } catch (error) {
    console.error('Get photo gallery error:', error);
    res.status(500).json({ message: 'Server error retrieving photo gallery' });
  }
};

// Organize photos (trigger manual organization)
exports.organizePhotos = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Trigger photo organization
    const result = await fileStorage.organizePhotosByDate(userId);
    
    res.status(200).json({
      message: 'Photos organized successfully',
      ...result
    });
  } catch (error) {
    console.error('Organize photos error:', error);
    res.status(500).json({ message: 'Server error organizing photos' });
  }
};

// Get photo metadata
exports.getPhotoMetadata = async (req, res) => {
  try {
    const fileId = req.params.id;
    const userId = req.user.id;
    
    // Find file in database
    const fileResults = await db.select()
      .from(files)
      .where(and(
        eq(files.id, fileId),
        eq(files.userId, userId)
      ));
    
    if (fileResults.length === 0) {
      return res.status(404).json({ message: 'File not found' });
    }
    
    const file = fileResults[0];
    
    // Only images have additional metadata
    if (file.fileType !== 'image') {
      return res.status(400).json({ message: 'Metadata is only available for images' });
    }
    
    const filePath = path.join(__dirname, '..', file.filePath);
    
    // Extract metadata
    const metadata = await fileStorage.extractImageMetadata(filePath);
    
    res.status(200).json({
      id: file.id,
      name: file.originalName,
      metadata
    });
  } catch (error) {
    console.error('Get photo metadata error:', error);
    res.status(500).json({ message: 'Server error retrieving photo metadata' });
  }
};

// Check for files that need syncing (for auto-backup feature)
exports.getSyncStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const { lastSyncTime } = req.query;
    
    // If lastSyncTime provided, find files newer than that time
    let fileQuery = db.select().from(files).where(eq(files.userId, userId));
    
    if (lastSyncTime) {
      const syncDate = new Date(lastSyncTime);
      fileQuery = fileQuery.where(
        db.sql`${files.createdAt} > ${syncDate.toISOString()}`
      );
    }
    
    const fileResults = await fileQuery.orderBy(desc(files.createdAt));
    
    const syncStatus = {
      lastSyncTime: new Date().toISOString(),
      totalFiles: fileResults.length,
      newFiles: fileResults.map(file => ({
        id: file.id,
        name: file.originalName,
        size: file.fileSize,
        type: file.fileType,
        createdAt: file.createdAt
      })),
      storageStatus: {
        filesCount: fileResults.length,
        lastUpdated: new Date().toISOString()
      }
    };
    
    // Get user storage information
    const userResults = await db.select().from(users).where(eq(users.id, userId));
    
    if (userResults.length > 0) {
      const user = userResults[0];
      syncStatus.storageStatus.used = user.storageUsed;
      syncStatus.storageStatus.total = user.storageLimit;
      syncStatus.storageStatus.percentUsed = Math.round((user.storageUsed / user.storageLimit) * 100);
    }
    
    res.status(200).json(syncStatus);
  } catch (error) {
    console.error('Get sync status error:', error);
    res.status(500).json({ message: 'Server error retrieving sync status' });
  }
};
