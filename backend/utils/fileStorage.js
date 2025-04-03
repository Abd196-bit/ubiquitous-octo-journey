const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Simple thumbnail generation (just copies the original file for now)
// In a production environment, this would use image processing libraries
exports.generateThumbnail = async (filePath, userId) => {
  try {
    const thumbnailDir = path.join(__dirname, '..', 'uploads', userId, 'thumbnails');
    
    // Create thumbnail directory if it doesn't exist
    if (!fs.existsSync(thumbnailDir)) {
      fs.mkdirSync(thumbnailDir, { recursive: true });
    }
    
    // Generate thumbnail filename
    const originalFilename = path.basename(filePath);
    const thumbnailFilename = `thumb_${uuidv4()}_${originalFilename}`;
    const thumbnailPath = path.join(thumbnailDir, thumbnailFilename);
    
    // For now, we'll just copy the original file as a placeholder
    // In a real implementation, we would resize the image
    fs.copyFileSync(filePath, thumbnailPath);
    
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
