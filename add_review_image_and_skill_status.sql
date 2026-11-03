-- Migration: Add image_url to reviews and status to skills
-- Run this in Supabase SQL Editor

ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.skills ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved';
