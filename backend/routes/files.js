const express = require('express');
const router = express.Router();
const fileController = require('../controllers/fileController');
const auth = require('../middleware/auth');

// Get all files for the authenticated user
// GET /api/files
router.get('/', auth, fileController.getFiles);

// Get file by ID
// GET /api/files/:id
router.get('/:id', auth, fileController.getFileById);

// Upload file
// POST /api/files/upload
router.post('/upload', auth, fileController.uploadMiddleware, fileController.uploadFile);

// Batch upload files (for iCloud-like sync)
// POST /api/files/batch-upload
router.post('/batch-upload', auth, fileController.batchUploadMiddleware, fileController.batchUploadFiles);

// Download file
// GET /api/files/:id/download
router.get('/:id/download', auth, fileController.downloadFile);

// Delete file
// DELETE /api/files/:id
router.delete('/:id', auth, fileController.deleteFile);

// Get file type summary (count and size by type)
// GET /api/files/summary/types
router.get('/summary/types', auth, fileController.getFileTypeSummary);

// Get files organized by date (like iCloud Photos)
// GET /api/files/photos/by-date
router.get('/photos/by-date', auth, fileController.getPhotosByDate);

// Get optimized thumbnail gallery (for faster browsing)
// GET /api/files/photos/gallery
router.get('/photos/gallery', auth, fileController.getPhotoGallery);

// Organize photos by date (trigger manual organization)
// POST /api/files/photos/organize
router.post('/photos/organize', auth, fileController.organizePhotos);

// Get photo metadata
// GET /api/files/:id/metadata
router.get('/:id/metadata', auth, fileController.getPhotoMetadata);

// Check if files need syncing (for auto-backup)
// GET /api/files/sync/status
router.get('/sync/status', auth, fileController.getSyncStatus);

module.exports = router;
