-- Phase 7: Performance Indexing & Gap Filling
-- Run this in Supabase SQL Editor

DO $$
BEGIN

    -- 1. Ensure Critical Columns Exist (Gap Filling)
    
    -- Assets: serial_number (Essential for search/scan)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assets') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'serial_number') THEN
             ALTER TABLE assets ADD COLUMN serial_number TEXT;
             RAISE NOTICE 'Added serial_number column to assets table';
        END IF;
    END IF;

    -- Assets: status (Essential for filtering)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assets') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'status') THEN
             ALTER TABLE assets ADD COLUMN status TEXT DEFAULT 'in_stock';
             RAISE NOTICE 'Added status column to assets table';
        END IF;
    END IF;

    -- Locations: company_id (Ensure link exists)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'locations') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'locations' AND column_name = 'company_id') THEN
             ALTER TABLE locations ADD COLUMN company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;
             RAISE NOTICE 'Added company_id column to locations table';
        END IF;
    END IF;

    -- 2. Create Indexes (Performance)

    -- Assets: Serial Number (High cardinality, frequent search)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'serial_number') THEN
        CREATE INDEX IF NOT EXISTS idx_assets_serial_number ON assets(serial_number);
    END IF;

    -- Assets: Status (Frequent filter)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_assets_status ON assets(status);
    END IF;
    
    -- Assets: Purchase Date (Depreciation calculations)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'purchase_date') THEN
        CREATE INDEX IF NOT EXISTS idx_assets_purchase_date ON assets(purchase_date);
    END IF;

    -- Locations: Company ID (Security & Filtering)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'locations' AND column_name = 'company_id') THEN
        CREATE INDEX IF NOT EXISTS idx_locations_company_id ON locations(company_id);
    END IF;

END $$;
