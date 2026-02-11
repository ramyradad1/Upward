-- Phase 5: Digital Handover & Analytics Migration
-- Run this in Supabase SQL Editor

-- 1. Create handovers table
CREATE TABLE IF NOT EXISTS handovers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  asset_id UUID NOT NULL,
  asset_name TEXT,
  from_user_id TEXT,
  from_user_name TEXT,
  to_user_id TEXT NOT NULL,
  to_user_name TEXT NOT NULL,
  issuer_signature_url TEXT,
  recipient_signature_url TEXT,
  notes TEXT,
  pdf_url TEXT,
  company_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add new columns to assets table (if not exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'last_handover_date'
  ) THEN
    ALTER TABLE assets ADD COLUMN last_handover_date TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'custody_document_url'
  ) THEN
    ALTER TABLE assets ADD COLUMN custody_document_url TEXT;
  END IF;
END $$;

-- 3. Enable RLS
ALTER TABLE handovers ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for handovers
CREATE POLICY "allow_authenticated_select_handovers"
  ON handovers FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_insert_handovers"
  ON handovers FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_update_handovers"
  ON handovers FOR UPDATE
  USING (auth.role() = 'authenticated');

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_handovers_asset ON handovers(asset_id);
CREATE INDEX IF NOT EXISTS idx_handovers_to_user ON handovers(to_user_id);
CREATE INDEX IF NOT EXISTS idx_handovers_company ON handovers(company_id);
CREATE INDEX IF NOT EXISTS idx_handovers_created ON handovers(created_at DESC);

-- 6. Create storage buckets (run these separately if needed)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('signatures', 'signatures', true)
-- ON CONFLICT (id) DO NOTHING;
-- INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', true)
-- ON CONFLICT (id) DO NOTHING;
