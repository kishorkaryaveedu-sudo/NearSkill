-- ============================================================
-- NEARSKILL – Seed Data
-- Run AFTER schema.sql and custom_auth.sql
-- ============================================================

-- ── Skills (15 categories) ───────────────────────────────────
INSERT INTO public.skills (skill_name) VALUES
  ('Plumbing'),
  ('Electrical'),
  ('Carpentry'),
  ('Painting'),
  ('Cleaning'),
  ('Gardening'),
  ('AC Repair'),
  ('TV Repair'),
  ('Appliance Repair'),
  ('Moving'),
  ('Pest Control'),
  ('Welding'),
  ('Masonry'),
  ('Tutoring'),
  ('Driving')
ON CONFLICT (skill_name) DO NOTHING;

-- ── Demo Users (password: password123) ───────────────────────
INSERT INTO public.users (full_name, email, mobile_number, password_hash)
SELECT 'Rahul Sharma', 'rahul@demo.com', '9876543210',
       crypt('password123', gen_salt('bf'))
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'rahul@demo.com');

INSERT INTO public.users (full_name, email, mobile_number, password_hash)
SELECT 'Suresh Kumar', 'suresh@demo.com', '9123456789',
       crypt('password123', gen_salt('bf'))
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'suresh@demo.com');

INSERT INTO public.users (full_name, email, mobile_number, password_hash)
SELECT 'Priya Nair', 'priya@demo.com', '9444556677',
       crypt('password123', gen_salt('bf'))
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'priya@demo.com');

-- ── Demo Worker Profiles ─────────────────────────────────────
-- Suresh: Plumber in Bangalore
INSERT INTO public.worker_profiles (
  user_id, experience_years, hourly_rate,
  availability_status, current_latitude, current_longitude,
  average_rating, verification_status
)
SELECT u.user_id, 5, 350, true, 12.9716, 77.5946, 4.5, 'verified'
FROM public.users u WHERE u.email = 'suresh@demo.com'
AND NOT EXISTS (
  SELECT 1 FROM public.worker_profiles wp WHERE wp.user_id = u.user_id
);

-- Priya: Electrician in Bangalore
INSERT INTO public.worker_profiles (
  user_id, experience_years, hourly_rate,
  availability_status, current_latitude, current_longitude,
  average_rating, verification_status
)
SELECT u.user_id, 3, 275, true, 12.9352, 77.6245, 4.2, 'verified'
FROM public.users u WHERE u.email = 'priya@demo.com'
AND NOT EXISTS (
  SELECT 1 FROM public.worker_profiles wp WHERE wp.user_id = u.user_id
);

-- ── Worker Skills ────────────────────────────────────────────
INSERT INTO public.worker_skills (worker_id, skill_id)
SELECT wp.worker_id, s.skill_id
FROM public.worker_profiles wp
JOIN public.users u ON u.user_id = wp.user_id
JOIN public.skills s ON s.skill_name IN ('Plumbing', 'Carpentry')
WHERE u.email = 'suresh@demo.com'
ON CONFLICT (worker_id, skill_id) DO NOTHING;

INSERT INTO public.worker_skills (worker_id, skill_id)
SELECT wp.worker_id, s.skill_id
FROM public.worker_profiles wp
JOIN public.users u ON u.user_id = wp.user_id
JOIN public.skills s ON s.skill_name IN ('Electrical', 'AC Repair')
WHERE u.email = 'priya@demo.com'
ON CONFLICT (worker_id, skill_id) DO NOTHING;
