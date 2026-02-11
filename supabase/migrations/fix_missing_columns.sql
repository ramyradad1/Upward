-- Fix: Add missing columns required by AssetModel
-- Run this in Supabase SQL Editor

DO $$
BEGIN
  -- Basic Fields
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'image_urls'
  ) THEN
    ALTER TABLE assets ADD COLUMN image_urls TEXT[];
  END IF;

  -- Handover / Assignment Fields
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'custody_image_url'
  ) THEN
    ALTER TABLE assets ADD COLUMN custody_image_url TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'id_card_image_url'
  ) THEN
    ALTER TABLE assets ADD COLUMN id_card_image_url TEXT;
  END IF;
  
  -- Accessories
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'bag_type'
  ) THEN
    ALTER TABLE assets ADD COLUMN bag_type TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'headset_type'
  ) THEN
    ALTER TABLE assets ADD COLUMN headset_type TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'headset_serial'
  ) THEN
    ALTER TABLE assets ADD COLUMN headset_serial TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'mouse_type'
  ) THEN
    ALTER TABLE assets ADD COLUMN mouse_type TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'mouse_serial'
  ) THEN
    ALTER TABLE assets ADD COLUMN mouse_serial TEXT;
  END IF;

  -- Phase 1: Deep Specs & Network
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'location_id'
  ) THEN
    ALTER TABLE assets ADD COLUMN location_id UUID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'location_name'
  ) THEN
    ALTER TABLE assets ADD COLUMN location_name TEXT;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'cpu'
  ) THEN
    ALTER TABLE assets ADD COLUMN cpu TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'ram'
  ) THEN
    ALTER TABLE assets ADD COLUMN ram TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'storage_spec'
  ) THEN
    ALTER TABLE assets ADD COLUMN storage_spec TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'hostname'
  ) THEN
    ALTER TABLE assets ADD COLUMN hostname TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'ip_address'
  ) THEN
    ALTER TABLE assets ADD COLUMN ip_address TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'mac_address'
  ) THEN
    ALTER TABLE assets ADD COLUMN mac_address TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'notes'
  ) THEN
    ALTER TABLE assets ADD COLUMN notes TEXT;
  END IF;

  -- Phase 2: Network Intelligence & Security
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'config_file_url'
  ) THEN
    ALTER TABLE assets ADD COLUMN config_file_url TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'config_file_name'
  ) THEN
    ALTER TABLE assets ADD COLUMN config_file_name TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'secure_credentials'
  ) THEN
    ALTER TABLE assets ADD COLUMN secure_credentials TEXT;
  END IF;

  -- Phase 3: Field Operations
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'last_seen_lat'
  ) THEN
    ALTER TABLE assets ADD COLUMN last_seen_lat DOUBLE PRECISION;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'last_seen_lng'
  ) THEN
    ALTER TABLE assets ADD COLUMN last_seen_lng DOUBLE PRECISION;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'last_seen_at'
  ) THEN
    ALTER TABLE assets ADD COLUMN last_seen_at TIMESTAMPTZ;
  END IF;

END $$;
