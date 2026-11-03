-- ============================================================
-- NEARSKILL – Round 3 Update
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add is_banned to users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT false;

-- Create support_tickets table
CREATE TABLE IF NOT EXISTS public.support_tickets (
  ticket_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
