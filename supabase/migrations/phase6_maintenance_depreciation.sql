-- Phase 6: Maintenance Scheduling & Asset Depreciation
-- Run this in Supabase SQL Editor

-- 1. Create maintenance_schedules table
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  asset_id UUID,           -- NULL = applies to location/general
  asset_name TEXT,
  location_id UUID,
  location_name TEXT,
  frequency TEXT NOT NULL DEFAULT 'monthly', -- 'daily','weekly','monthly','quarterly','semi_annual','annual','one_time'
  priority TEXT NOT NULL DEFAULT 'medium',   -- 'low','medium','high','critical'
  assigned_to TEXT,        -- Technician name
  last_performed_at TIMESTAMPTZ,
  next_due_date TIMESTAMPTZ NOT NULL,
  estimated_duration_minutes INTEGER,
  estimated_cost NUMERIC(12,2),
  currency TEXT DEFAULT 'SAR',
  is_active BOOLEAN DEFAULT TRUE,
  company_id UUID,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create maintenance_logs table
CREATE TABLE IF NOT EXISTS maintenance_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_id UUID REFERENCES maintenance_schedules(id) ON DELETE SET NULL,
  asset_id UUID,
  asset_name TEXT,
  title TEXT NOT NULL,
  description TEXT,
  performed_by TEXT NOT NULL,
  performed_at TIMESTAMPTZ DEFAULT NOW(),
  duration_minutes INTEGER,
  cost NUMERIC(12,2),
  currency TEXT DEFAULT 'SAR',
  status TEXT NOT NULL DEFAULT 'completed', -- 'completed','partial','failed'
  parts_replaced TEXT,     -- JSON or free text
  notes TEXT,
  before_photo_url TEXT,
  after_photo_url TEXT,
  company_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add depreciation & warranty columns to assets table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'purchase_price'
  ) THEN
    ALTER TABLE assets ADD COLUMN purchase_price NUMERIC(12,2);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'purchase_date'
  ) THEN
    ALTER TABLE assets ADD COLUMN purchase_date TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'currency'
  ) THEN
    ALTER TABLE assets ADD COLUMN currency TEXT DEFAULT 'SAR';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'depreciation_method'
  ) THEN
    ALTER TABLE assets ADD COLUMN depreciation_method TEXT DEFAULT 'straight_line';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'useful_life_years'
  ) THEN
    ALTER TABLE assets ADD COLUMN useful_life_years INTEGER;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'salvage_value'
  ) THEN
    ALTER TABLE assets ADD COLUMN salvage_value NUMERIC(12,2) DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'warranty_expiry'
  ) THEN
    ALTER TABLE assets ADD COLUMN warranty_expiry TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assets' AND column_name = 'next_maintenance_date'
  ) THEN
    ALTER TABLE assets ADD COLUMN next_maintenance_date TIMESTAMPTZ;
  END IF;
END $$;

-- 4. Enable RLS
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for maintenance_schedules
CREATE POLICY "allow_authenticated_select_schedules"
  ON maintenance_schedules FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_insert_schedules"
  ON maintenance_schedules FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_update_schedules"
  ON maintenance_schedules FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_delete_schedules"
  ON maintenance_schedules FOR DELETE
  USING (auth.role() = 'authenticated');

-- 6. RLS Policies for maintenance_logs
CREATE POLICY "allow_authenticated_select_logs"
  ON maintenance_logs FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_insert_logs"
  ON maintenance_logs FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "allow_authenticated_update_logs"
  ON maintenance_logs FOR UPDATE
  USING (auth.role() = 'authenticated');

-- 7. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_maint_schedules_asset ON maintenance_schedules(asset_id);
CREATE INDEX IF NOT EXISTS idx_maint_schedules_company ON maintenance_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_maint_schedules_next_due ON maintenance_schedules(next_due_date);
CREATE INDEX IF NOT EXISTS idx_maint_schedules_active ON maintenance_schedules(is_active);
CREATE INDEX IF NOT EXISTS idx_maint_logs_schedule ON maintenance_logs(schedule_id);
CREATE INDEX IF NOT EXISTS idx_maint_logs_asset ON maintenance_logs(asset_id);
CREATE INDEX IF NOT EXISTS idx_maint_logs_company ON maintenance_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_maint_logs_performed ON maintenance_logs(performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_assets_warranty ON assets(warranty_expiry);
CREATE INDEX IF NOT EXISTS idx_assets_next_maint ON assets(next_maintenance_date);

-- 8. Enable realtime for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_schedules;
ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_logs;
