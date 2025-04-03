CREATE TABLE IF NOT EXISTS "users" (
        "id" serial PRIMARY KEY NOT NULL,
        "name" varchar(255) NOT NULL,
        "email" varchar(255) NOT NULL,
        "password" varchar(255) NOT NULL,
        "storage_used" bigint DEFAULT 0,
        "storage_limit" bigint DEFAULT 5368709120,
        "created_at" timestamp DEFAULT now(),
        "last_login_at" timestamp,
        "avatar_url" text,
        "phone_number" varchar(20),
        "is_verified" boolean DEFAULT false,
        "two_factor_enabled" boolean DEFAULT false,
        "two_factor_secret" varchar(100),
        "reset_password_token" varchar(100),
        "reset_password_expires" timestamp,
        "subscription" varchar(50) DEFAULT 'free',
        "subscription_expires" timestamp,
        "is_auto_backup_enabled" boolean DEFAULT true,
        "auto_backup_frequency" varchar(20) DEFAULT 'daily',
        "preferred_theme" varchar(20) DEFAULT 'system',
        "language" varchar(10) DEFAULT 'en',
        "push_notifications_enabled" boolean DEFAULT true,
        "device_tokens" text,
        "last_sync_at" timestamp,
        CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "files" (
        "id" serial PRIMARY KEY NOT NULL,
        "user_id" serial NOT NULL,
        "original_name" varchar(255) NOT NULL,
        "file_name" varchar(255) NOT NULL,
        "file_path" text NOT NULL,
        "thumbnail_path" text,
        "file_type" varchar(50),
        "file_size" bigint NOT NULL,
        "is_public" boolean DEFAULT false,
        "created_at" timestamp DEFAULT now(),
        "updated_at" timestamp DEFAULT now(),
        "content_hash" varchar(64),
        "mime_type" varchar(100),
        "extension" varchar(20),
        "is_hidden" boolean DEFAULT false,
        "is_archived" boolean DEFAULT false,
        "is_starred" boolean DEFAULT false,
        "is_shared" boolean DEFAULT false,
        "share_token" varchar(100),
        "last_accessed" timestamp,
        "tags" text,
        CONSTRAINT "files_file_name_unique" UNIQUE("file_name")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "photo_metadata" (
        "id" serial PRIMARY KEY NOT NULL,
        "file_id" integer NOT NULL,
        "date_taken" timestamp,
        "latitude" numeric(10, 8),
        "longitude" numeric(11, 8),
        "camera_model" varchar(100),
        "resolution" varchar(50),
        "organized" boolean DEFAULT false,
        "organized_path" text,
        "year" integer,
        "month" integer,
        "day" integer,
        "has_gps_data" boolean DEFAULT false,
        "location_name" varchar(255),
        "is_hdr" boolean DEFAULT false,
        "color_tags" text,
        "ai_tags" text,
        "is_favorite" boolean DEFAULT false
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "folders" (
        "id" serial PRIMARY KEY NOT NULL,
        "user_id" integer NOT NULL,
        "name" varchar(255) NOT NULL,
        "parent_id" integer,
        "path" text NOT NULL,
        "is_root" boolean DEFAULT false,
        "created_at" timestamp DEFAULT now(),
        "updated_at" timestamp DEFAULT now(),
        "is_hidden" boolean DEFAULT false,
        "is_archived" boolean DEFAULT false,
        "color" varchar(20)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "file_folder_relations" (
        "id" serial PRIMARY KEY NOT NULL,
        "file_id" integer NOT NULL,
        "folder_id" integer NOT NULL,
        "is_primary" boolean DEFAULT true
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "shares" (
        "id" serial PRIMARY KEY NOT NULL,
        "user_id" integer NOT NULL,
        "file_id" integer,
        "folder_id" integer,
        "share_token" varchar(100) NOT NULL,
        "share_type" varchar(20) DEFAULT 'view',
        "password" varchar(255),
        "expires_at" timestamp,
        "max_downloads" integer,
        "download_count" integer DEFAULT 0,
        "created_at" timestamp DEFAULT now(),
        "last_accessed_at" timestamp,
        "is_active" boolean DEFAULT true,
        "allowed_emails" text,
        CONSTRAINT "shares_share_token_unique" UNIQUE("share_token")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "shared_access" (
        "id" serial PRIMARY KEY NOT NULL,
        "share_id" integer NOT NULL,
        "accessed_by" varchar(255),
        "accessed_at" timestamp DEFAULT now(),
        "access_type" varchar(20),
        "device_info" text
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "albums" (
        "id" serial PRIMARY KEY NOT NULL,
        "user_id" integer NOT NULL,
        "name" varchar(255) NOT NULL,
        "description" text,
        "cover_photo_id" integer,
        "created_at" timestamp DEFAULT now(),
        "updated_at" timestamp DEFAULT now(),
        "is_hidden" boolean DEFAULT false,
        "is_shared" boolean DEFAULT false,
        "share_token" varchar(100),
        "is_smart" boolean DEFAULT false,
        "smart_rules" text
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "album_photos" (
        "id" serial PRIMARY KEY NOT NULL,
        "album_id" integer NOT NULL,
        "file_id" integer NOT NULL,
        "added_at" timestamp DEFAULT now(),
        "order" integer DEFAULT 0
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "devices" (
        "id" serial PRIMARY KEY NOT NULL,
        "user_id" integer NOT NULL,
        "device_id" varchar(255) NOT NULL,
        "device_name" varchar(255),
        "device_type" varchar(50),
        "os_version" varchar(50),
        "app_version" varchar(50),
        "last_sync_at" timestamp,
        "push_token" varchar(255),
        "is_active" boolean DEFAULT true,
        "created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "files" ADD CONSTRAINT "files_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "photo_metadata" ADD CONSTRAINT "photo_metadata_file_id_files_id_fk" FOREIGN KEY ("file_id") REFERENCES "files"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "folders" ADD CONSTRAINT "folders_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "folders" ADD CONSTRAINT "folders_parent_id_folders_id_fk" FOREIGN KEY ("parent_id") REFERENCES "folders"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "file_folder_relations" ADD CONSTRAINT "file_folder_relations_file_id_files_id_fk" FOREIGN KEY ("file_id") REFERENCES "files"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "file_folder_relations" ADD CONSTRAINT "file_folder_relations_folder_id_folders_id_fk" FOREIGN KEY ("folder_id") REFERENCES "folders"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "shares" ADD CONSTRAINT "shares_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "shares" ADD CONSTRAINT "shares_file_id_files_id_fk" FOREIGN KEY ("file_id") REFERENCES "files"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "shares" ADD CONSTRAINT "shares_folder_id_folders_id_fk" FOREIGN KEY ("folder_id") REFERENCES "folders"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "shared_access" ADD CONSTRAINT "shared_access_share_id_shares_id_fk" FOREIGN KEY ("share_id") REFERENCES "shares"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "albums" ADD CONSTRAINT "albums_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "albums" ADD CONSTRAINT "albums_cover_photo_id_files_id_fk" FOREIGN KEY ("cover_photo_id") REFERENCES "files"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "album_photos" ADD CONSTRAINT "album_photos_album_id_albums_id_fk" FOREIGN KEY ("album_id") REFERENCES "albums"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "album_photos" ADD CONSTRAINT "album_photos_file_id_files_id_fk" FOREIGN KEY ("file_id") REFERENCES "files"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
-- Create indexes for optimized queries
CREATE INDEX IF NOT EXISTS "idx_files_file_type" ON "files" ("file_type");
CREATE INDEX IF NOT EXISTS "idx_files_created_at" ON "files" ("created_at");
CREATE INDEX IF NOT EXISTS "idx_files_user_id" ON "files" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_photo_metadata_date_taken" ON "photo_metadata" ("date_taken");
CREATE INDEX IF NOT EXISTS "idx_photo_metadata_year" ON "photo_metadata" ("year");
CREATE INDEX IF NOT EXISTS "idx_photo_metadata_month" ON "photo_metadata" ("month");
CREATE INDEX IF NOT EXISTS "idx_photo_metadata_location" ON "photo_metadata" ("latitude", "longitude");
CREATE INDEX IF NOT EXISTS "idx_folders_user_id" ON "folders" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_folders_parent_id" ON "folders" ("parent_id");
CREATE INDEX IF NOT EXISTS "idx_albums_user_id" ON "albums" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_devices_user_id" ON "devices" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_shares_user_id" ON "shares" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_shares_token" ON "shares" ("share_token");
CREATE INDEX IF NOT EXISTS "idx_file_folder_file_id" ON "file_folder_relations" ("file_id");
CREATE INDEX IF NOT EXISTS "idx_file_folder_folder_id" ON "file_folder_relations" ("folder_id");
CREATE INDEX IF NOT EXISTS "idx_album_photos_album_id" ON "album_photos" ("album_id");
CREATE INDEX IF NOT EXISTS "idx_album_photos_file_id" ON "album_photos" ("file_id");
