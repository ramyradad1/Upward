-- Phase 3 Migration: Field Operations

-- 1. Add Geolocation columns to assets table
ALTER TABLE assets 
ADD COLUMN IF NOT EXISTS last_seen_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_seen_lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;

-- 2. Create Audit Sessions table (if not already created in previous steps, but good to ensure)
CREATE TABLE IF NOT EXISTS audit_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID REFERENCES locations(id),
    location_name TEXT,
    performed_by TEXT, -- Email or User ID
    status TEXT DEFAULT 'in_progress', -- in_progress, completed
    scanned_items JSONB DEFAULT '[]'::jsonb, -- List of ScannedItem
    missing_items TEXT[] DEFAULT '{}', -- Array of serial numbers
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    company_id UUID -- Optional, for RLS
);

-- 3. RLS for audit_sessions
ALTER TABLE audit_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read/write for authenticated users" ON audit_sessions
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- 4. Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_audit_sessions_location ON audit_sessions(location_id);
CREATE INDEX IF NOT EXISTS idx_audit_sessions_created_at ON audit_sessions(created_at);
