const jwt = require('jsonwebtoken');
const { eq } = require('drizzle-orm');
const db = require('../db');
const { users } = require('../db/schema');

// JWT secret key
const JWT_SECRET = process.env.JWT_SECRET || 'cloudstore_secret_key';

// Authentication middleware
module.exports = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.header('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' from the string
    
    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Find user by ID from token
    const userResults = await db.select().from(users).where(eq(users.id, decoded.id));
    
    if (userResults.length === 0) {
      return res.status(401).json({ message: 'Invalid token, user not found' });
    }
    
    // Set user in request object
    req.user = {
      id: decoded.id
    };
    
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired' });
    }
    
    res.status(500).json({ message: 'Server error in authentication' });
  }
};
