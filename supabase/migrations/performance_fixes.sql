-- Performance Fixes & Missing Columns Migration
-- Generated based on Systematic Debugging: Root Cause Analysis

DO $$
BEGIN
    -- 0. Ensure Critical Columns Exist (Root Cause Fix)
    
    -- Assets: company_id is required by AssetModel
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assets') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'company_id') THEN
            ALTER TABLE assets ADD COLUMN company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE; 
            -- Note: We add it as nullable first to avoid issues with existing data. 
            RAISE NOTICE 'Added company_id column to assets table';
        END IF;
    END IF;

    -- Profiles: company_id is required by ProfileService
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'company_id') THEN
             ALTER TABLE profiles ADD COLUMN company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;
             RAISE NOTICE 'Added company_id column to profiles table';
        END IF;
    END IF;

    -- Assets: location_id (Phase 1)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assets') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'location_id') THEN
             ALTER TABLE assets ADD COLUMN location_id UUID;
             RAISE NOTICE 'Added location_id column to assets table';
        END IF;
    END IF;

    -- Profiles: role
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role') THEN
             ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
             RAISE NOTICE 'Added role column to profiles table';
        END IF;
    END IF;

    -- Maintenance Schedules: location_id
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'maintenance_schedules') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_schedules' AND column_name = 'location_id') THEN
             ALTER TABLE maintenance_schedules ADD COLUMN location_id UUID;
             RAISE NOTICE 'Added location_id column to maintenance_schedules table';
        END IF;
    END IF;
    
    -- Audit Sessions: company_id
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_sessions') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_sessions' AND column_name = 'company_id') THEN
             ALTER TABLE audit_sessions ADD COLUMN company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;
             RAISE NOTICE 'Added company_id column to audit_sessions table';
        END IF;
    END IF;

    -- 1. Create Indexes (Performance Fix)
    
    -- Assets
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'company_id') THEN
        CREATE INDEX IF NOT EXISTS idx_assets_company_id ON assets(company_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assets' AND column_name = 'location_id') THEN
        CREATE INDEX IF NOT EXISTS idx_assets_location_id ON assets(location_id);
    END IF;

    -- Profiles
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'company_id') THEN
            CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role') THEN
            CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'id') THEN
            CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(id);
        END IF;
    END IF;

    -- Employees
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'company_id') THEN
        CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);
    END IF;

    -- Audit Sessions
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_sessions' AND column_name = 'company_id') THEN
        CREATE INDEX IF NOT EXISTS idx_audit_sessions_company_id ON audit_sessions(company_id);
    END IF;

    -- Requests & Approvals
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'requests_approvals') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'requests_approvals' AND column_name = 'approver_id') THEN
            CREATE INDEX IF NOT EXISTS idx_requests_approvals_approver_id ON requests_approvals(approver_id);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'requests_approvals' AND column_name = 'asset_id') THEN
            CREATE INDEX IF NOT EXISTS idx_requests_approvals_asset_id ON requests_approvals(asset_id);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'requests_approvals' AND column_name = 'from_location_id') THEN
            CREATE INDEX IF NOT EXISTS idx_requests_approvals_from_location_id ON requests_approvals(from_location_id);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'requests_approvals' AND column_name = 'to_location_id') THEN
            CREATE INDEX IF NOT EXISTS idx_requests_approvals_to_location_id ON requests_approvals(to_location_id);
        END IF;
    END IF;

    -- Maintenance Schedules
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_schedules' AND column_name = 'location_id') THEN
        CREATE INDEX IF NOT EXISTS idx_maintenance_schedules_location_id ON maintenance_schedules(location_id);
    END IF;
    
    -- Handovers
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'handovers' AND column_name = 'from_user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_handovers_from_user_id ON handovers(from_user_id);
    END IF;

END $$;
