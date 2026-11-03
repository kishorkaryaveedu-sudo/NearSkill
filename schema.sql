-- ============================================================
-- NEARSKILL – Full Database Schema
-- Based on the official ER Diagram
-- Run this FIRST in Supabase SQL Editor
-- ============================================================

-- ── Extensions ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Drop EVERYTHING (reverse dependency order) ───────────────
DROP TABLE IF EXISTS public.reviews          CASCADE;
DROP TABLE IF EXISTS public.chat_messages    CASCADE;
DROP TABLE IF EXISTS public.service_requests CASCADE;
DROP TABLE IF EXISTS public.worker_skills    CASCADE;
DROP TABLE IF EXISTS public.skills           CASCADE;
DROP TABLE IF EXISTS public.worker_profiles  CASCADE;
DROP TABLE IF EXISTS public.admins           CASCADE;
DROP TABLE IF EXISTS public.users            CASCADE;

-- ============================================================
-- 1. User
-- ============================================================
CREATE TABLE public.users (
  user_id           UUID        DEFAULT uuid_generate_v4() PRIMARY KEY,
  full_name         TEXT        NOT NULL,
  email             TEXT        UNIQUE NOT NULL,
  mobile_number     TEXT,
  password_hash     TEXT        NOT NULL,
  role              TEXT        NOT NULL DEFAULT 'user',
  profile_photo_url TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. Admin
-- ============================================================
CREATE TABLE public.admins (
  admin_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id  UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  role     TEXT NOT NULL DEFAULT 'admin'
);

-- ============================================================
-- 3. WorkerProfile
-- ============================================================
CREATE TABLE public.worker_profiles (
  worker_id           UUID    DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id             UUID    UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  profile_photo_url   TEXT,
  experience_years    INT     NOT NULL DEFAULT 0,
  hourly_rate         NUMERIC NOT NULL DEFAULT 0,
  availability_status BOOLEAN NOT NULL DEFAULT true,
  current_latitude    FLOAT   NOT NULL DEFAULT 0,
  current_longitude   FLOAT   NOT NULL DEFAULT 0,
  average_rating      FLOAT   NOT NULL DEFAULT 0,
  verification_status TEXT    NOT NULL DEFAULT 'pending',
  id_card_url         TEXT,
  id_card_type        TEXT,
  verification_notes  TEXT
);

-- ============================================================
-- 4. Skill
-- ============================================================
CREATE TABLE public.skills (
  skill_id   UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  skill_name TEXT UNIQUE NOT NULL
);

-- ============================================================
-- 5. WorkerSkill
-- ============================================================
CREATE TABLE public.worker_skills (
  worker_id UUID NOT NULL REFERENCES public.worker_profiles(worker_id) ON DELETE CASCADE,
  skill_id  UUID NOT NULL REFERENCES public.skills(skill_id) ON DELETE CASCADE,
  PRIMARY KEY (worker_id, skill_id)
);

-- ============================================================
-- 6. ServiceRequest
-- ============================================================
CREATE TABLE public.service_requests (
  request_id   UUID        DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id      UUID        NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  worker_id    UUID        NOT NULL REFERENCES public.worker_profiles(worker_id) ON DELETE CASCADE,
  status       TEXT        NOT NULL DEFAULT 'pending',
  agreed_price NUMERIC,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- ============================================================
-- 7. ChatMessage
-- ============================================================
CREATE TABLE public.chat_messages (
  message_id       UUID        DEFAULT uuid_generate_v4() PRIMARY KEY,
  request_id       UUID        NOT NULL REFERENCES public.service_requests(request_id) ON DELETE CASCADE,
  sender_user_id   UUID        NOT NULL REFERENCES public.users(user_id),
  receiver_user_id UUID        NOT NULL REFERENCES public.users(user_id),
  message_content  TEXT        NOT NULL,
  message_type     TEXT        NOT NULL DEFAULT 'text',
  image_url        TEXT,
  timestamp        TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. Review
-- ============================================================
CREATE TABLE public.reviews (
  review_id       UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  request_id      UUID UNIQUE NOT NULL REFERENCES public.service_requests(request_id) ON DELETE CASCADE,
  reviewer_user_id UUID NOT NULL REFERENCES public.users(user_id),
  rated_worker_id  UUID NOT NULL REFERENCES public.worker_profiles(worker_id),
  rating          INT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DISABLE RLS (we use custom auth, not Supabase JWT)
-- ============================================================
ALTER TABLE public.users            DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admins           DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_profiles  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills           DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_skills    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews          DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- GRANTS
-- ============================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES    IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- ============================================================
-- Round 3 & 4 additions
-- ============================================================
-- ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT false;

/*
CREATE TABLE IF NOT EXISTS public.support_tickets (
  ticket_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  admin_response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
*/
