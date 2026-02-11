-- Copy and paste this into your Supabase SQL Editor to fix the missing table error.

-- 1. Create the employees table
CREATE TABLE IF NOT EXISTS public.employees (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    name TEXT NOT NULL,
    company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE
);

-- 2. Enable RLS (Row Level Security) is recommended, but for now we'll ensure it's accessible
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- 3. Create policies to allow access
-- Allow anyone to read employees (you might want to restrict this later)
CREATE POLICY "Allow public read access" ON public.employees
    FOR SELECT USING (true);

-- Allow authenticated users to create employees
CREATE POLICY "Allow authenticated insert" ON public.employees
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update/delete
CREATE POLICY "Allow authenticated update" ON public.employees
    FOR UPDATE USING (auth.role() = 'authenticated');

-- 4. Create index on foreign key for performance
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON public.employees(company_id);
