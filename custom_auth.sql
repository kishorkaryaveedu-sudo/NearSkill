-- ============================================================
-- NEARSKILL – Custom Auth Functions
-- Run AFTER schema.sql in Supabase SQL Editor
-- ============================================================

-- Drop old versions
DROP FUNCTION IF EXISTS public.register_custom_user(text, text, text, text, text);
DROP FUNCTION IF EXISTS public.register_custom_user(text, text, text, text);
DROP FUNCTION IF EXISTS public.login_custom_user(text, text);
DROP FUNCTION IF EXISTS public.reset_user_password(text, text);

-- ============================================================
-- register_custom_user  (no role – matches ER diagram)
-- ============================================================
CREATE OR REPLACE FUNCTION public.register_custom_user(
  p_email         TEXT,
  p_password      TEXT,
  p_full_name     TEXT,
  p_mobile_number TEXT DEFAULT NULL
) RETURNS json AS $$
DECLARE
  new_id UUID;
  result json;
BEGIN
  IF EXISTS (SELECT 1 FROM public.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Email already registered';
  END IF;

  INSERT INTO public.users (full_name, email, mobile_number, password_hash)
  VALUES (p_full_name, p_email, p_mobile_number, crypt(p_password, gen_salt('bf')))
  RETURNING user_id INTO new_id;

  SELECT row_to_json(u)
  FROM (
    SELECT user_id, full_name, email, mobile_number, created_at
    FROM public.users WHERE user_id = new_id
  ) u INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- login_custom_user
-- ============================================================
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
        SELECT u.user_id, u.full_name, u.email, u.mobile_number, u.created_at
      ) r
    ));
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- reset_user_password
-- ============================================================
CREATE OR REPLACE FUNCTION public.reset_user_password(
  p_email        TEXT,
  p_new_password TEXT
) RETURNS json AS $$
DECLARE
  target_id UUID;
  result json;
BEGIN
  SELECT user_id INTO target_id FROM public.users WHERE email = p_email;

  IF target_id IS NULL THEN
    RAISE EXCEPTION 'No account found for this email';
  END IF;

  UPDATE public.users
  SET password_hash = crypt(p_new_password, gen_salt('bf'))
  WHERE user_id = target_id;

  SELECT row_to_json(u)
  FROM (
    SELECT user_id, full_name, email, mobile_number, created_at
    FROM public.users WHERE user_id = target_id
  ) u INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Grants
-- ============================================================
GRANT EXECUTE ON FUNCTION public.register_custom_user(text, text, text, text)
  TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.login_custom_user(text, text)
  TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reset_user_password(text, text)
  TO anon, authenticated, service_role;
