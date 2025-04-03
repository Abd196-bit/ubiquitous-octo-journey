const { pgTable, serial, text, timestamp, varchar, boolean, integer, bigint, decimal } = require('drizzle-orm/pg-core');

const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),
  storageUsed: bigint('storage_used', { mode: 'number' }).default(0),
  storageLimit: bigint('storage_limit', { mode: 'number' }).default(5 * 1024 * 1024 * 1024), // 5GB default
  createdAt: timestamp('created_at').defaultNow()
});

const files = pgTable('files', {
  id: serial('id').primaryKey(),
  userId: serial('user_id').references(() => users.id),
  originalName: varchar('original_name', { length: 255 }).notNull(),
  fileName: varchar('file_name', { length: 255 }).notNull(),
  filePath: text('file_path').notNull(),
  thumbnailPath: text('thumbnail_path'),
  fileType: varchar('file_type', { length: 50 }),
  fileSize: bigint('file_size', { mode: 'number' }).notNull(),
  isPublic: boolean('is_public').default(false),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});

const photoMetadata = pgTable('photo_metadata', {
  id: serial('id').primaryKey(),
  fileId: integer('file_id').references(() => files.id, { onDelete: 'cascade' }).notNull(),
  dateTaken: timestamp('date_taken'),
  latitude: decimal('latitude', { precision: 10, scale: 8 }),
  longitude: decimal('longitude', { precision: 11, scale: 8 }),
  cameraModel: varchar('camera_model', { length: 100 }),
  resolution: varchar('resolution', { length: 50 }),
  organized: boolean('organized').default(false),
  organizedPath: text('organized_path')
});

module.exports = {
  users,
  files,
  photoMetadata
};