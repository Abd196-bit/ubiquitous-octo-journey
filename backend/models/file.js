/**
 * File model utility functions
 * Contains utility methods for working with file data
 * For the actual schema, refer to db/schema.js
 */

/**
 * Format file size to human-readable format
 * @param {number} bytes - Size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted size with unit
 */
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Get file extension from filename
 * @param {string} filename - Original filename
 * @returns {string} - Lowercase file extension without dot
 */
exports.getExtension = (filename) => {
  const parts = filename.split('.');
  return parts.length > 1 ? parts.pop().toLowerCase() : '';
};

/**
 * Determine file type based on extension
 * @param {string} filename - Original filename
 * @returns {string} - File type category (image, video, document, audio, or other)
 */
exports.getFileType = (filename) => {
  const extension = exports.getExtension(filename);
  
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp', 'heic'];
  const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', 'm4v'];
  const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf', 'csv'];
  const audioExtensions = ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'];
  
  if (imageExtensions.includes(extension)) return 'image';
  if (videoExtensions.includes(extension)) return 'video';
  if (documentExtensions.includes(extension)) return 'document';
  if (audioExtensions.includes(extension)) return 'audio';
  
  return 'other';
};

/**
 * Format file size to human-readable format
 * @param {number} bytes - Size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted size with unit
 */
exports.formatBytes = formatBytes;
