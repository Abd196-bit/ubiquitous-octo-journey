const { pgTable, serial, text, timestamp, varchar, boolean, integer } = require('drizzle-orm/pg-core');

const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),
  storageUsed: integer('storage_used').default(0),
  storageLimit: integer('storage_limit').default(5 * 1024 * 1024 * 1024), // 5GB default
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
  fileSize: integer('file_size').notNull(),
  isPublic: boolean('is_public').default(false),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});

module.exports = {
  users,
  files
};