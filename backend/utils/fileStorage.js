const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { promisify } = require('util');
const exec = promisify(require('child_process').exec);

/**
 * Generate a proper thumbnail for image files using ImageMagick (if available)
 * Falls back to copying if conversion fails
 * @param {string} filePath - Path to the original file
 * @param {string|number} userId - User ID for directory organization
 * @returns {string|null} - Relative path to the generated thumbnail
 */
exports.generateThumbnail = async (filePath, userId) => {
  try {
    // Ensure userId is a string
    const userIdStr = String(userId);
    const thumbnailDir = path.join(__dirname, '..', 'uploads', userIdStr, 'thumbnails');
    
    // Create thumbnail directory if it doesn't exist
    if (!fs.existsSync(thumbnailDir)) {
      fs.mkdirSync(thumbnailDir, { recursive: true });
    }
    
    // Generate thumbnail filename
    const originalFilename = path.basename(filePath);
    const thumbnailFilename = `thumb_${uuidv4()}_${originalFilename}`;
    const thumbnailPath = path.join(thumbnailDir, thumbnailFilename);
    
    // Check file extension to determine if it's an image
    const ext = path.extname(filePath).toLowerCase();
    const isImage = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].includes(ext);
    
    if (isImage) {
      try {
        // Try to use ImageMagick to create a proper thumbnail (max 300x300)
        await exec(`convert "${filePath}" -thumbnail 300x300^ -gravity center -extent 300x300 "${thumbnailPath}"`);
        console.log(`Thumbnail created for ${originalFilename}`);
      } catch (imgError) {
        console.error('ImageMagick not available, falling back to copy:', imgError);
        fs.copyFileSync(filePath, thumbnailPath);
      }
    } else {
      // For non-image files, just copy the file as placeholder
      fs.copyFileSync(filePath, thumbnailPath);
    }
    
    // Return the relative path to the thumbnail
    return path.relative(path.join(__dirname, '..'), thumbnailPath);
  } catch (error) {
    console.error('Error generating thumbnail:', error);
    return null;
  }
};

// Check if file exists
exports.fileExists = (filePath) => {
  return fs.existsSync(filePath);
};

// Get file size
exports.getFileSize = (filePath) => {
  try {
    const stats = fs.statSync(filePath);
    return stats.size;
  } catch (error) {
    console.error('Error getting file size:', error);
    return 0;
  }
};

// Delete file
exports.deleteFile = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error deleting file:', error);
    return false;
  }
};

// Get all files in a directory
exports.getFilesInDirectory = (dirPath) => {
  try {
    if (!fs.existsSync(dirPath)) {
      return [];
    }
    
    return fs.readdirSync(dirPath).filter(file => {
      return fs.statSync(path.join(dirPath, file)).isFile();
    });
  } catch (error) {
    console.error('Error getting files in directory:', error);
    return [];
  }
};

// Create a directory if it doesn't exist
exports.createDirectory = (dirPath) => {
  try {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error creating directory:', error);
    return false;
  }
};

// Get directory size by summing up all file sizes
exports.getDirectorySize = (dirPath) => {
  try {
    if (!fs.existsSync(dirPath)) {
      return 0;
    }
    
    let totalSize = 0;
    
    const files = fs.readdirSync(dirPath);
    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const stats = fs.statSync(filePath);
      
      if (stats.isFile()) {
        totalSize += stats.size;
      } else if (stats.isDirectory()) {
        totalSize += this.getDirectorySize(filePath);
      }
    }
    
    return totalSize;
  } catch (error) {
    console.error('Error getting directory size:', error);
    return 0;
  }
};

/**
 * Extract image metadata like date taken, location, etc.
 * Uses exiftool or other commands if available, falls back to file stats
 * @param {string} filePath - Path to the image file
 * @returns {Object} - Object containing metadata information
 */
exports.extractImageMetadata = async (filePath) => {
  const metadata = {
    dateTaken: null,
    location: null,
    camera: null,
    resolution: null,
    fileCreated: new Date(),
    fileModified: new Date()
  };
  
  try {
    // First get basic file stats
    const stats = fs.statSync(filePath);
    metadata.fileCreated = stats.birthtime;
    metadata.fileModified = stats.mtime;
    
    // Try to use exiftool if available
    try {
      const { stdout } = await exec(`exiftool -json "${filePath}"`);
      const exifData = JSON.parse(stdout)[0];
      
      if (exifData) {
        // Extract date taken
        if (exifData.DateTimeOriginal) {
          metadata.dateTaken = new Date(exifData.DateTimeOriginal);
        } else if (exifData.CreateDate) {
          metadata.dateTaken = new Date(exifData.CreateDate);
        }
        
        // Extract location data
        if (exifData.GPSLatitude && exifData.GPSLongitude) {
          metadata.location = {
            latitude: exifData.GPSLatitude,
            longitude: exifData.GPSLongitude
          };
        }
        
        // Extract camera info
        if (exifData.Make || exifData.Model) {
          metadata.camera = `${exifData.Make || ''} ${exifData.Model || ''}`.trim();
        }
        
        // Extract resolution
        if (exifData.ImageWidth && exifData.ImageHeight) {
          metadata.resolution = `${exifData.ImageWidth}x${exifData.ImageHeight}`;
        }
      }
    } catch (exifError) {
      // ExifTool not available, just continue with basic file info
      console.log('ExifTool not available, using basic file stats');
    }
    
    return metadata;
  } catch (error) {
    console.error('Error extracting image metadata:', error);
    return metadata;
  }
};

/**
 * Organize photos by date (like iCloud Photos)
 * @param {string|number} userId - User ID for directory organization
 * @returns {Object} - Object containing organizing results
 */
exports.organizePhotosByDate = async (userId) => {
  try {
    // Ensure userId is a string
    const userIdStr = String(userId);
    const photosDir = path.join(__dirname, '..', 'uploads', userIdStr);
    const organizedDir = path.join(photosDir, 'organized_photos');
    const stats = { organized: 0, failed: 0, total: 0 };
    
    // Create organized photos directory if it doesn't exist
    if (!fs.existsSync(organizedDir)) {
      fs.mkdirSync(organizedDir, { recursive: true });
    }
    
    // Get all files in user's upload directory
    const processDirectory = async (dir) => {
      const files = fs.readdirSync(dir);
      
      for (const file of files) {
        const filePath = path.join(dir, file);
        const stats = fs.statSync(filePath);
        
        if (stats.isFile()) {
          // Check if it's an image file
          const ext = path.extname(filePath).toLowerCase();
          const isImage = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'].includes(ext);
          
          if (isImage) {
            try {
              await organizePhoto(filePath, organizedDir);
              stats.organized++;
            } catch (err) {
              stats.failed++;
              console.error(`Failed to organize photo ${filePath}:`, err);
            }
            stats.total++;
          }
        } else if (stats.isDirectory() && path.basename(filePath) !== 'organized_photos' && path.basename(filePath) !== 'thumbnails') {
          // Process subdirectories, but skip the organized_photos and thumbnails directories
          await processDirectory(filePath);
        }
      }
    };
    
    const organizePhoto = async (filePath, targetDir) => {
      // Extract metadata to determine the date
      const metadata = await this.extractImageMetadata(filePath);
      const photoDate = metadata.dateTaken || metadata.fileCreated;
      
      // Format dates for directory structure (YYYY/MM/DD)
      const year = photoDate.getFullYear();
      const month = String(photoDate.getMonth() + 1).padStart(2, '0');
      const day = String(photoDate.getDate()).padStart(2, '0');
      
      // Create directory structure
      const yearDir = path.join(targetDir, year.toString());
      const monthDir = path.join(yearDir, month);
      const dayDir = path.join(monthDir, day);
      
      for (const dir of [yearDir, monthDir, dayDir]) {
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
      }
      
      // Copy file to organized location (don't move to preserve original)
      const destFilename = path.basename(filePath);
      const destPath = path.join(dayDir, destFilename);
      
      // If file already exists, add a unique identifier
      if (fs.existsSync(destPath)) {
        const uniqueId = uuidv4().substring(0, 8);
        const fileExt = path.extname(destFilename);
        const fileName = path.basename(destFilename, fileExt);
        const newDestPath = path.join(dayDir, `${fileName}_${uniqueId}${fileExt}`);
        fs.copyFileSync(filePath, newDestPath);
      } else {
        fs.copyFileSync(filePath, destPath);
      }
    };
    
    await processDirectory(photosDir);
    return stats;
  } catch (error) {
    console.error('Error organizing photos:', error);
    return { organized: 0, failed: 0, total: 0, error: error.message };
  }
};
