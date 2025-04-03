# CloudStore

A multi-platform cloud storage solution designed to efficiently manage smartphone file storage with intelligent optimization and cross-device synchronization.

## Features

- Cloud-based file management with secure authentication
- Mobile-first design (iOS, Android support)
- Intelligent file organization and backup
- Secure remote file storage and retrieval
- Automatic thumbnail generation for images
- Metadata extraction and organization

## Technology Stack

### Backend
- Node.js
- Express.js
- PostgreSQL with Drizzle ORM
- JWT Authentication
- File processing with ImageMagick

### iOS Client
- Swift
- MVC Architecture
- UIKit
- Camera access and file management

## Project Structure

```
├── backend               # Node.js server
│   ├── controllers       # Request handlers
│   ├── db                # Database connection and schema
│   ├── middleware        # Authentication middleware
│   ├── models            # Data models
│   ├── routes            # API routes
│   └── utils             # Utility functions
├── ios_app               # iOS application
│   └── CloudStore        # Swift project
```

## Getting Started

### Prerequisites
- Node.js 14+
- PostgreSQL 12+
- For iOS development: Xcode 12+, macOS

### Backend Setup
1. Navigate to the backend directory
   ```
   cd backend
   ```
2. Install dependencies
   ```
   npm install
   ```
3. Create a .env file with the following variables:
   ```
   DATABASE_URL=postgresql://username:password@localhost:5432/cloudstore
   JWT_SECRET=your_jwt_secret
   PORT=5000
   ```
4. Start the server
   ```
   npm start
   ```

### iOS App Setup
1. Open the project in Xcode
   ```
   open ios_app/CloudStore/CloudStore.xcodeproj
   ```
2. Update the API URL in `Constants.swift` to point to your backend server
3. Build and run the app on a simulator or device

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get JWT token

### Files
- `GET /api/files` - Get all files for authenticated user
- `POST /api/files/upload` - Upload a new file
- `GET /api/files/:id` - Download a specific file
- `DELETE /api/files/:id` - Delete a file

## License
This project is licensed under the MIT License