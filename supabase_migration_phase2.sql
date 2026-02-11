-- ============================================
-- Phase 2: Database Migration
-- ============================================

-- 2.1 & 2.2: Add columns to assets table
ALTER TABLE assets ADD COLUMN IF NOT EXISTS secure_credentials TEXT;
ALTER TABLE assets ADD COLUMN IF NOT EXISTS config_file_url TEXT;
ALTER TABLE assets ADD COLUMN IF NOT EXISTS config_file_name TEXT;

-- 2.3: Create licenses table
CREATE TABLE IF NOT EXISTS licenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'saas',
  vendor TEXT,
  total_seats INTEGER NOT NULL DEFAULT 1,
  used_seats INTEGER NOT NULL DEFAULT 0,
  purchase_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  cost_per_seat NUMERIC(10,2),
  currency TEXT DEFAULT 'USD',
  billing_cycle TEXT,
  license_key TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read/write licenses
CREATE POLICY "Enable all access for authenticated users"
  ON licenses
  FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_licenses_company_id ON licenses(company_id);
CREATE INDEX IF NOT EXISTS idx_licenses_type ON licenses(type);
CREATE INDEX IF NOT EXISTS idx_licenses_expiry_date ON licenses(expiry_date);

-- Enable realtime for licenses table
ALTER PUBLICATION supabase_realtime ADD TABLE licenses;
