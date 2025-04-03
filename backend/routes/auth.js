const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Register a new user
// POST /api/auth/register
router.post('/register', authController.register);

// Login user
// POST /api/auth/login
router.post('/login', authController.login);

// Get current user info
// GET /api/auth/user
router.get('/user', auth, authController.getCurrentUser);

// Update user profile
// PUT /api/auth/user
router.put('/user', auth, authController.updateUser);

// Change password
// PUT /api/auth/password
router.put('/password', auth, authController.changePassword);

module.exports = router;
