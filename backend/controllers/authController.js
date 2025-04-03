const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const { eq } = require('drizzle-orm');
const db = require('../db');
const { users } = require('../db/schema');

// JWT config
const JWT_SECRET = process.env.JWT_SECRET || 'cloudstore_secret_key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

// Register a new user
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Please provide name, email and password' });
    }

    // Check if email already exists
    const existingUser = await db.select().from(users).where(eq(users.email, email));
    if (existingUser.length > 0) {
      return res.status(400).json({ message: 'Email already in use' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const [insertedUser] = await db.insert(users).values({
      name,
      email,
      password: hashedPassword
    }).returning();

    // Create user directory for uploads
    const userUploadDir = path.join(__dirname, '..', 'uploads', insertedUser.id.toString());
    if (!fs.existsSync(userUploadDir)) {
      fs.mkdirSync(userUploadDir, { recursive: true });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: insertedUser.id },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      token,
      user: {
        id: insertedUser.id,
        name: insertedUser.name,
        email: insertedUser.email
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
};

// Login user
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    // Find user by email
    const userResults = await db.select().from(users).where(eq(users.email, email));
    
    if (userResults.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    const user = userResults[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(200).json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// Get current user
exports.getCurrentUser = async (req, res) => {
  try {
    const userResults = await db.select({
      id: users.id,
      name: users.name,
      email: users.email,
      createdAt: users.createdAt
    }).from(users).where(eq(users.id, req.user.id));
    
    if (userResults.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResults[0];

    res.status(200).json({
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error getting user information' });
  }
};

// Update user profile
exports.updateUser = async (req, res) => {
  try {
    const { name, email } = req.body;
    
    // Get user
    const userResults = await db.select().from(users).where(eq(users.id, req.user.id));
    
    if (userResults.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResults[0];
    
    // Prepare update object
    const updates = {};
    if (name) updates.name = name;
    
    if (email && email !== user.email) {
      // Check if email already exists
      const existingUser = await db.select().from(users).where(eq(users.email, email));
      if (existingUser.length > 0) {
        return res.status(400).json({ message: 'Email already in use' });
      }
      updates.email = email;
    }
    
    // Update user
    if (Object.keys(updates).length > 0) {
      await db.update(users)
        .set(updates)
        .where(eq(users.id, req.user.id));
    }
    
    // Get updated user
    const updatedUserResults = await db.select().from(users).where(eq(users.id, req.user.id));
    const updatedUser = updatedUserResults[0];
    
    res.status(200).json({
      id: updatedUser.id,
      name: updatedUser.name,
      email: updatedUser.email
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Server error updating user' });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    // Validate input
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Please provide current and new password' });
    }
    
    // Get user with password
    const userResults = await db.select().from(users).where(eq(users.id, req.user.id));
    
    if (userResults.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const user = userResults[0];
    
    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }
    
    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Update password
    await db.update(users)
      .set({ password: hashedPassword })
      .where(eq(users.id, req.user.id));
    
    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: 'Server error changing password' });
  }
};
