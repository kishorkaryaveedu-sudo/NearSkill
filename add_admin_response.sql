-- Add admin_response to support_tickets
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS admin_response TEXT;
