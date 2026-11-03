-- ============================================================
-- NEARSKILL – Critical Fixes Migration
-- Run this in Supabase SQL Editor
-- ============================================================

-- ── 1. Fix login_custom_user to return is_banned, role, profile_photo_url ──
DROP FUNCTION IF EXISTS public.login_custom_user(text, text);

CREATE OR REPLACE FUNCTION public.login_custom_user(
  p_email    TEXT,
  p_password TEXT
) RETURNS json AS $$
DECLARE
  u record;
BEGIN
  SELECT * FROM public.users WHERE email = p_email INTO u;

  IF u.user_id IS NULL THEN
    RETURN NULL;
  END IF;

  IF u.password_hash = crypt(p_password, u.password_hash) THEN
    RETURN row_to_json((
      SELECT r FROM (
        SELECT u.user_id, u.full_name, u.email, u.mobile_number,
               u.profile_photo_url, u.role, u.is_banned, u.created_at
      ) r
    ));
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.login_custom_user(text, text)
  TO anon, authenticated, service_role;

-- ── 2. Fix chat_messages FK constraints to CASCADE on delete ──
ALTER TABLE public.chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_sender_user_id_fkey;

ALTER TABLE public.chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_receiver_user_id_fkey;

ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_sender_user_id_fkey
    FOREIGN KEY (sender_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_receiver_user_id_fkey
    FOREIGN KEY (receiver_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

-- ── 3. Ensure support_tickets has admin_response column ──
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS admin_response TEXT;

-- ── 4. Add subject column to support_tickets ──
ALTER TABLE public.support_tickets ADD COLUMN IF NOT EXISTS subject TEXT;

-- ── 5. Disable RLS on support_tickets (custom auth) ──
ALTER TABLE public.support_tickets DISABLE ROW LEVEL SECURITY;

-- ── 6. Grants ──
GRANT ALL ON public.support_tickets TO anon, authenticated, service_role;
