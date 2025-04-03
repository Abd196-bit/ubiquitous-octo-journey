const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { eq } = require('drizzle-orm');
const db = require('../db');
const { users, files } = require('../db/schema');
const fileStorage = require('../utils/fileStorage');

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const userId = req.user.id;
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
    
    // SQL query to get file type summary
    const query = `
      SELECT 
        file_type as type, 
        COUNT(*) as count, 
        SUM(file_size) as "totalSize"
      FROM files 
      WHERE user_id = $1
      GROUP BY file_type
    `;
    
    const fileSummary = await db.execute(query, [userId]);
    
    res.status(200).json(fileSummary);
  } catch (error) {
    console.error('Get file type summary error:', error);
    res.status(500).json({ message: 'Server error retrieving file summary' });
  }
};
