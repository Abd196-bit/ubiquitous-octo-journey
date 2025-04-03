const { pgTable, serial, text, timestamp, varchar, boolean, integer, bigint, decimal, index } = require('drizzle-orm/pg-core');

const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),
  storageUsed: bigint('storage_used', { mode: 'number' }).default(0),
  storageLimit: bigint('storage_limit', { mode: 'number' }).default(5 * 1024 * 1024 * 1024), // 5GB default
  createdAt: timestamp('created_at').defaultNow(),
  // Additional user profile and account management fields
  lastLoginAt: timestamp('last_login_at'),
  avatarUrl: text('avatar_url'),
  phoneNumber: varchar('phone_number', { length: 20 }),
  isVerified: boolean('is_verified').default(false), // Email verification
  twoFactorEnabled: boolean('two_factor_enabled').default(false),
  twoFactorSecret: varchar('two_factor_secret', { length: 100 }),
  resetPasswordToken: varchar('reset_password_token', { length: 100 }),
  resetPasswordExpires: timestamp('reset_password_expires'),
  subscription: varchar('subscription', { length: 50 }).default('free'),
  subscriptionExpires: timestamp('subscription_expires'),
  isAutoBackupEnabled: boolean('is_auto_backup_enabled').default(true),
  autoBackupFrequency: varchar('auto_backup_frequency', { length: 20 }).default('daily'),
  preferredTheme: varchar('preferred_theme', { length: 20 }).default('system'),
  language: varchar('language', { length: 10 }).default('en'),
  pushNotificationsEnabled: boolean('push_notifications_enabled').default(true),
  deviceTokens: text('device_tokens'), // JSON array of device tokens for push notifications
  lastSyncAt: timestamp('last_sync_at') // When user's device last synced with cloud
});

const files = pgTable('files', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id).notNull(),
  originalName: varchar('original_name', { length: 255 }).notNull(),
  fileName: varchar('file_name', { length: 255 }).notNull().unique(),
  filePath: text('file_path').notNull(),
  thumbnailPath: text('thumbnail_path'),
  fileType: varchar('file_type', { length: 50 }), // Will add index separately
  fileSize: bigint('file_size', { mode: 'number' }).notNull(),
  isPublic: boolean('is_public').default(false),
  createdAt: timestamp('created_at').defaultNow(), // Will add index separately
  updatedAt: timestamp('updated_at').defaultNow(),
  // Additional fields for enhanced file management
  contentHash: varchar('content_hash', { length: 64 }), // For duplicate detection
  mimeType: varchar('mime_type', { length: 100 }), // More specific than fileType
  extension: varchar('extension', { length: 20 }), // File extension without dot
  isHidden: boolean('is_hidden').default(false), // Allow users to hide files
  isArchived: boolean('is_archived').default(false), // For "soft delete" functionality
  isStarred: boolean('is_starred').default(false), // User can star important files
  isShared: boolean('is_shared').default(false), // Whether the file is shared with others
  shareToken: varchar('share_token', { length: 100 }), // Token for sharing files
  lastAccessed: timestamp('last_accessed'), // Track when file was last accessed
  tags: text('tags') // JSON array of user-defined tags
});

const photoMetadata = pgTable('photo_metadata', {
  id: serial('id').primaryKey(),
  fileId: integer('file_id').references(() => files.id, { onDelete: 'cascade' }).notNull(),
  dateTaken: timestamp('date_taken'), // Will add index separately
  latitude: decimal('latitude', { precision: 10, scale: 8 }),
  longitude: decimal('longitude', { precision: 11, scale: 8 }),
  cameraModel: varchar('camera_model', { length: 100 }),
  resolution: varchar('resolution', { length: 50 }),
  organized: boolean('organized').default(false),
  organizedPath: text('organized_path'),
  // Additional fields to enhance photo organization
  year: integer('year'), // Extracted year from dateTaken for easier organization
  month: integer('month'), // Extracted month from dateTaken
  day: integer('day'), // Extracted day from dateTaken
  hasGpsData: boolean('has_gps_data').default(false), // Quick check if location data exists
  locationName: varchar('location_name', { length: 255 }), // Reverse geocoded location name
  isHdr: boolean('is_hdr').default(false), // Flag for HDR photos
  colorTags: text('color_tags'), // JSON-encoded color analysis for smart organization
  aiTags: text('ai_tags'), // Future: AI-generated tags for content recognition
  isFavorite: boolean('is_favorite').default(false) // User marked as favorite
});

// Create a folders table for better organization
const folders = pgTable('folders', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id).notNull(),
  name: varchar('name', { length: 255 }).notNull(),
  parentId: integer('parent_id').references(() => folders.id), // Self-reference for nesting
  path: text('path').notNull(), // Full path for easy traversal
  isRoot: boolean('is_root').default(false),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
  isHidden: boolean('is_hidden').default(false),
  isArchived: boolean('is_archived').default(false),
  color: varchar('color', { length: 20 }) // User can set folder colors
});

// Add a file_folder_relation table for many-to-many relationships
const fileFolderRelations = pgTable('file_folder_relations', {
  id: serial('id').primaryKey(),
  fileId: integer('file_id').references(() => files.id, { onDelete: 'cascade' }).notNull(),
  folderId: integer('folder_id').references(() => folders.id, { onDelete: 'cascade' }).notNull(),
  isPrimary: boolean('is_primary').default(true) // Is this the main folder for the file
});

// Create a shares table for managing shared content
const shares = pgTable('shares', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id).notNull(), // Owner
  fileId: integer('file_id').references(() => files.id, { onDelete: 'cascade' }),
  folderId: integer('folder_id').references(() => folders.id, { onDelete: 'cascade' }),
  shareToken: varchar('share_token', { length: 100 }).notNull().unique(),
  shareType: varchar('share_type', { length: 20 }).default('view'), // view, edit, etc.
  password: varchar('password', { length: 255 }), // Optional password protection
  expiresAt: timestamp('expires_at'), // Optional expiration
  maxDownloads: integer('max_downloads'), // Optional download limit
  downloadCount: integer('download_count').default(0),
  createdAt: timestamp('created_at').defaultNow(),
  lastAccessedAt: timestamp('last_accessed_at'),
  isActive: boolean('is_active').default(true),
  allowedEmails: text('allowed_emails') // JSON array of emails that can access
});

// Create a shared_access table to track who accessed shared content
const sharedAccess = pgTable('shared_access', {
  id: serial('id').primaryKey(),
  shareId: integer('share_id').references(() => shares.id, { onDelete: 'cascade' }).notNull(),
  accessedBy: varchar('accessed_by', { length: 255 }), // Email or IP
  accessedAt: timestamp('accessed_at').defaultNow(),
  accessType: varchar('access_type', { length: 20 }), // view, download, etc.
  deviceInfo: text('device_info') // User agent and other device details
});

// Create an albums table for photo organization
const albums = pgTable('albums', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id).notNull(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  coverPhotoId: integer('cover_photo_id').references(() => files.id),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
  isHidden: boolean('is_hidden').default(false),
  isShared: boolean('is_shared').default(false),
  shareToken: varchar('share_token', { length: 100 }),
  isSmart: boolean('is_smart').default(false), // Smart albums are auto-populated
  smartRules: text('smart_rules') // JSON rules for smart album population
});

// Create an album_photos table for many-to-many relationship
const albumPhotos = pgTable('album_photos', {
  id: serial('id').primaryKey(),
  albumId: integer('album_id').references(() => albums.id, { onDelete: 'cascade' }).notNull(),
  fileId: integer('file_id').references(() => files.id, { onDelete: 'cascade' }).notNull(),
  addedAt: timestamp('added_at').defaultNow(),
  order: integer('order').default(0) // For manual ordering of photos in album
});

// Create a devices table to track user devices
const devices = pgTable('devices', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id).notNull(),
  deviceId: varchar('device_id', { length: 255 }).notNull(),
  deviceName: varchar('device_name', { length: 255 }),
  deviceType: varchar('device_type', { length: 50 }), // mobile, tablet, desktop
  osVersion: varchar('os_version', { length: 50 }),
  appVersion: varchar('app_version', { length: 50 }),
  lastSyncAt: timestamp('last_sync_at'),
  pushToken: varchar('push_token', { length: 255 }),
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow()
});

// Define indexes
const fileTypeIdx = index('idx_files_file_type', files.fileType);
const filesCreatedAtIdx = index('idx_files_created_at', files.createdAt);
const filesUserIdIdx = index('idx_files_user_id', files.userId);
const photoMetadataDateTakenIdx = index('idx_photo_metadata_date_taken', photoMetadata.dateTaken);
const photoMetadataYearIdx = index('idx_photo_metadata_year', photoMetadata.year);
const photoMetadataMonthIdx = index('idx_photo_metadata_month', photoMetadata.month);
const photoMetadataLocationIdx = index('idx_photo_metadata_location', [photoMetadata.latitude, photoMetadata.longitude]);
const folderUserIdIdx = index('idx_folders_user_id', folders.userId);
const folderParentIdIdx = index('idx_folders_parent_id', folders.parentId);
const albumUserIdIdx = index('idx_albums_user_id', albums.userId);
const deviceUserIdIdx = index('idx_devices_user_id', devices.userId);
const sharesUserIdIdx = index('idx_shares_user_id', shares.userId);
const sharesTokenIdx = index('idx_shares_token', shares.shareToken);
const fileFolderFileIdIdx = index('idx_file_folder_file_id', fileFolderRelations.fileId);
const fileFolderFolderIdIdx = index('idx_file_folder_folder_id', fileFolderRelations.folderId);
const albumPhotosAlbumIdIdx = index('idx_album_photos_album_id', albumPhotos.albumId);
const albumPhotosFileIdIdx = index('idx_album_photos_file_id', albumPhotos.fileId);

// Export all tables and indexes
module.exports = {
  users,
  files,
  photoMetadata,
  folders,
  fileFolderRelations,
  shares,
  sharedAccess,
  albums,
  albumPhotos,
  devices,
  // Indexes
  fileTypeIdx,
  filesCreatedAtIdx,
  filesUserIdIdx,
  photoMetadataDateTakenIdx,
  photoMetadataYearIdx,
  photoMetadataMonthIdx,
  photoMetadataLocationIdx,
  folderUserIdIdx,
  folderParentIdIdx,
  albumUserIdIdx,
  deviceUserIdIdx,
  sharesUserIdIdx,
  sharesTokenIdx,
  fileFolderFileIdIdx,
  fileFolderFolderIdIdx,
  albumPhotosAlbumIdIdx,
  albumPhotosFileIdIdx
};