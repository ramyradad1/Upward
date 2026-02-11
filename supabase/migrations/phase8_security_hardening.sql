-- Phase 8: Security Hardening & Tenant Isolation
-- Run this in Supabase SQL Editor

-- 1. Enable RLS on all sensitive tables
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing permissive policies (if any) to avoid security holes
-- We wrap in DO block to avoid errors if they don't exist
DO $$
BEGIN
    -- Assets
    DROP POLICY IF EXISTS "Enable read access for all users" ON assets;
    DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON assets;
    DROP POLICY IF EXISTS "Enable update for users based on email" ON assets;
    DROP POLICY IF EXISTS "Enable delete for users based on email" ON assets;
    
    -- Employees
    DROP POLICY IF EXISTS "Allow public read access" ON employees;
    DROP POLICY IF EXISTS "Allow authenticated insert" ON employees;
    DROP POLICY IF EXISTS "Allow authenticated update" ON employees;

    -- Maintenance (from Phase 6)
    DROP POLICY IF EXISTS "allow_authenticated_select_schedules" ON maintenance_schedules;
    DROP POLICY IF EXISTS "allow_authenticated_insert_schedules" ON maintenance_schedules;
    DROP POLICY IF EXISTS "allow_authenticated_update_schedules" ON maintenance_schedules;
    DROP POLICY IF EXISTS "allow_authenticated_delete_schedules" ON maintenance_schedules;

    DROP POLICY IF EXISTS "allow_authenticated_select_logs" ON maintenance_logs;
    DROP POLICY IF EXISTS "allow_authenticated_insert_logs" ON maintenance_logs;
    DROP POLICY IF EXISTS "allow_authenticated_update_logs" ON maintenance_logs;
END $$;

-- 3. Create Tenant-Isolated Policies

-- Helper comment:
-- We assume `auth.uid()` maps to a `profiles` row that has a `company_id`.
-- Policies checking `company_id` ensure users can ONLY see data from their company.

-- === PROFILES ===
-- Users can read their own profile
CREATE POLICY "Users can read own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admins/Coworkers can read profiles from SAME company (needed for dropdowns, requests)
CREATE POLICY "Users can read coworkers profiles" ON profiles
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- === ASSETS ===
-- View: Same Company
CREATE POLICY "View assets from own company" ON assets
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- Insert: Must assign to own company
CREATE POLICY "Create assets for own company" ON assets
    FOR INSERT WITH CHECK (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- Update: Own company
CREATE POLICY "Update assets from own company" ON assets
    FOR UPDATE USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- Delete: Own company (Optional: restrict to admins only if 'role' column exists in profiles)
CREATE POLICY "Delete assets from own company" ON assets
    FOR DELETE USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- === LOCATIONS ===
CREATE POLICY "View locations from own company" ON locations
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "Manage locations from own company" ON locations
    FOR ALL USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- === EMPLOYEES ===
CREATE POLICY "View employees from own company" ON employees
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "Manage employees from own company" ON employees
    FOR ALL USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- === MAINTENANCE SCHEDULES ===
CREATE POLICY "View schedules from own company" ON maintenance_schedules
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "Manage schedules from own company" ON maintenance_schedules
    FOR ALL USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

-- === MAINTENANCE LOGS ===
CREATE POLICY "View maintenance logs from own company" ON maintenance_logs
    FOR SELECT USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "Manage maintenance logs from own company" ON maintenance_logs
    FOR ALL USING (
        company_id = (SELECT company_id FROM profiles WHERE id = auth.uid())
    );
