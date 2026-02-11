-- Phase 4: Workflows & Approvals Migration

-- 1. Create requests_approvals table
CREATE TABLE IF NOT EXISTS requests_approvals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID NOT NULL REFERENCES auth.users(id),
  requester_name TEXT,
  approver_id UUID REFERENCES auth.users(id),
  approver_name TEXT,
  type TEXT NOT NULL DEFAULT 'new_device', -- 'asset_transfer', 'new_device', 'repair', 'return_asset'
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  asset_id UUID, -- Optional link to asset
  asset_name TEXT,
  from_location_id UUID,
  to_location_id UUID,
  notes TEXT,
  reject_reason TEXT,
  company_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- 2. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL,
  body TEXT,
  type TEXT DEFAULT 'info', -- 'request_created', 'request_approved', 'request_rejected', 'info'
  reference_id UUID, -- Link to request or other object
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS
ALTER TABLE requests_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Requests: Users can view their own requests and admins/managers can view company requests
CREATE POLICY "Users can view their own requests" 
ON requests_approvals FOR SELECT 
USING (auth.uid() = requester_id);

CREATE POLICY "Admins can view company requests" 
ON requests_approvals FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.company_id = requests_approvals.company_id
    AND (profiles.role = 'admin' OR profiles.role = 'manager')
  )
);

CREATE POLICY "Users can create requests" 
ON requests_approvals FOR INSERT 
WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Admins can update requests" 
ON requests_approvals FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.company_id = requests_approvals.company_id
    AND (profiles.role = 'admin' OR profiles.role = 'manager')
  )
);

-- Notifications: Users can only view/update their own notifications
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE
USING (auth.uid() = user_id);
-- Allow system/functions to insert notifications (handled via service role in backend functions, 
-- but for client-side inserts we might need this if we trigger from client)
CREATE POLICY "Users receive notifications" 
ON notifications FOR INSERT 
WITH CHECK (true); -- Or stricter: auth.uid() = user_id (if self-trigger)

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_requests_requester ON requests_approvals(requester_id);
CREATE INDEX IF NOT EXISTS idx_requests_company ON requests_approvals(company_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests_approvals(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);
