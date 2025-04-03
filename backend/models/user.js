/**
 * User model utility functions
 * Contains utility methods for working with user data
 * For the actual schema, refer to db/schema.js
 */

/**
 * Calculate storage percentage used
 * @param {number} storageUsed - Storage space currently used in bytes
 * @param {number} storageLimit - Total storage limit in bytes
 * @returns {number} - Percentage of storage used (0-100)
 */
exports.calculateStoragePercentage = (storageUsed, storageLimit) => {
  if (!storageLimit) return 0;
  return Math.min(100, (storageUsed / storageLimit) * 100);
};

/**
 * Format bytes to human-readable format
 * @param {number} bytes - Size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted size with unit
 */
exports.formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};
