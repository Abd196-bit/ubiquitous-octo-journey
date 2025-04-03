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

// Download file
// GET /api/files/:id/download
router.get('/:id/download', auth, fileController.downloadFile);

// Delete file
// DELETE /api/files/:id
router.delete('/:id', auth, fileController.deleteFile);

// Get file type summary (count and size by type)
// GET /api/files/summary/types
router.get('/summary/types', auth, fileController.getFileTypeSummary);

module.exports = router;
