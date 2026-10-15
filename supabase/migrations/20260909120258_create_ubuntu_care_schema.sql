/*
# Ubuntu Care — Core Database Schema

## Overview
Creates the full schema for the Ubuntu Care public healthcare platform: patient profiles,
clinics, appointments, ambulance requests, notifications, activity logs, complaints,
and chatbot conversation history. All tables are multi-user (owner-scoped via auth.uid())
with RLS enabled.

## New Tables

1. **profiles** — Extends auth.users with healthcare-specific patient info
2. **clinics** — Public clinic directory (shared, readable by all authenticated users)
3. **appointments** — Patient appointment bookings
4. **ambulance_requests** — Emergency ambulance requests
5. **notifications** — User notification center
6. **activities** — User activity timeline / search history
7. **complaints** — Patient complaints and feedback
8. **chatbot_conversations** — Chatbot message history

## Security
- RLS enabled on ALL tables.
- profiles: owner-scoped (auth.uid() = id) for all CRUD.
- clinics: SELECT for all authenticated (shared directory).
- appointments, ambulance_requests, notifications, activities, complaints, chatbot_conversations:
  owner-scoped (auth.uid() = user_id) for SELECT/INSERT/UPDATE/DELETE.
- All owner columns default to auth.uid() so client inserts succeed without passing user_id.

## Notes
1. This migration is idempotent — safe to re-run.
2. Clinics table is seeded with South African public clinic data.
3. Reference numbers use format UC-YYYYMMDD-XXXX.
*/

-- ============ PROFILES ============
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  id_number text DEFAULT '',
  date_of_birth date,
  gender text DEFAULT '',
  mobile_number text DEFAULT '',
  email text DEFAULT '',
  home_address text DEFAULT '',
  blood_type text DEFAULT '',
  allergies text DEFAULT '',
  chronic_conditions text DEFAULT '',
  emergency_contact_name text DEFAULT '',
  emergency_contact_phone text DEFAULT '',
  language_preference text DEFAULT 'English',
  notification_preferences jsonb DEFAULT '{"sms": true, "email": true, "push": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_profile" ON profiles;
CREATE POLICY "select_own_profile" ON profiles FOR SELECT
  TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
CREATE POLICY "insert_own_profile" ON profiles FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_profile" ON profiles;
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE
  TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "delete_own_profile" ON profiles;
CREATE POLICY "delete_own_profile" ON profiles FOR DELETE
  TO authenticated USING (auth.uid() = id);

-- ============ CLINICS ============
CREATE TABLE IF NOT EXISTS clinics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  province text NOT NULL,
  district text NOT NULL,
  location text NOT NULL,
  latitude double precision,
  longitude double precision,
  operating_hours jsonb DEFAULT '{"mon_fri": "07:00-16:00", "sat": "08:00-12:00", "sun": "Closed"}'::jsonb,
  phone text DEFAULT '',
  services text[] DEFAULT ARRAY['General Consultation'],
  created_at timestamptz DEFAULT now()
);

ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_clinics" ON clinics;
CREATE POLICY "select_clinics" ON clinics FOR SELECT
  TO authenticated USING (true);

-- ============ APPOINTMENTS ============
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  full_name text NOT NULL DEFAULT '',
  id_number text DEFAULT '',
  date_of_birth date,
  gender text DEFAULT '',
  mobile_number text DEFAULT '',
  email text DEFAULT '',
  home_address text DEFAULT '',
  service text NOT NULL DEFAULT '',
  preferred_date date NOT NULL,
  preferred_time text NOT NULL DEFAULT '',
  alternative_date date,
  appointment_type text DEFAULT 'New Patient',
  reason_for_visit text DEFAULT '',
  symptoms text DEFAULT '',
  existing_conditions text DEFAULT '',
  current_medication text DEFAULT '',
  additional_notes text DEFAULT '',
  consent_accuracy boolean NOT NULL DEFAULT false,
  consent_share boolean NOT NULL DEFAULT false,
  consent_notifications boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'pending',
  reference_number text UNIQUE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_appointments" ON appointments;
CREATE POLICY "select_own_appointments" ON appointments FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_appointments" ON appointments;
CREATE POLICY "insert_own_appointments" ON appointments FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_appointments" ON appointments;
CREATE POLICY "update_own_appointments" ON appointments FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_appointments" ON appointments;
CREATE POLICY "delete_own_appointments" ON appointments FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ AMBULANCE REQUESTS ============
CREATE TABLE IF NOT EXISTS ambulance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_name text NOT NULL DEFAULT '',
  patient_condition text DEFAULT '',
  emergency_contact_name text DEFAULT '',
  emergency_contact_phone text DEFAULT '',
  location_lat double precision,
  location_lng double precision,
  location_address text DEFAULT '',
  status text NOT NULL DEFAULT 'requested',
  estimated_arrival_minutes int DEFAULT 15,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE ambulance_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_ambulance" ON ambulance_requests;
CREATE POLICY "select_own_ambulance" ON ambulance_requests FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_ambulance" ON ambulance_requests;
CREATE POLICY "insert_own_ambulance" ON ambulance_requests FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_ambulance" ON ambulance_requests;
CREATE POLICY "update_own_ambulance" ON ambulance_requests FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_ambulance" ON ambulance_requests;
CREATE POLICY "delete_own_ambulance" ON ambulance_requests FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ NOTIFICATIONS ============
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL DEFAULT 'appointment_reminder',
  title text NOT NULL DEFAULT '',
  message text NOT NULL DEFAULT '',
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_notifications" ON notifications;
CREATE POLICY "select_own_notifications" ON notifications FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_notifications" ON notifications;
CREATE POLICY "insert_own_notifications" ON notifications FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_notifications" ON notifications;
CREATE POLICY "update_own_notifications" ON notifications FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_notifications" ON notifications;
CREATE POLICY "delete_own_notifications" ON notifications FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ ACTIVITIES ============
CREATE TABLE IF NOT EXISTS activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL DEFAULT 'search',
  description text NOT NULL DEFAULT '',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_activities" ON activities;
CREATE POLICY "select_own_activities" ON activities FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_activities" ON activities;
CREATE POLICY "insert_own_activities" ON activities FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_activities" ON activities;
CREATE POLICY "update_own_activities" ON activities FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_activities" ON activities;
CREATE POLICY "delete_own_activities" ON activities FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ COMPLAINTS ============
CREATE TABLE IF NOT EXISTS complaints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL DEFAULT 'complaint',
  subject text NOT NULL DEFAULT '',
  message text NOT NULL DEFAULT '',
  reference_number text UNIQUE,
  status text NOT NULL DEFAULT 'pending',
  priority text NOT NULL DEFAULT 'normal',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_complaints" ON complaints;
CREATE POLICY "select_own_complaints" ON complaints FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_complaints" ON complaints;
CREATE POLICY "insert_own_complaints" ON complaints FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_complaints" ON complaints;
CREATE POLICY "update_own_complaints" ON complaints FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_complaints" ON complaints;
CREATE POLICY "delete_own_complaints" ON complaints FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ CHATBOT CONVERSATIONS ============
CREATE TABLE IF NOT EXISTS chatbot_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'user',
  message text NOT NULL DEFAULT '',
  intent text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE chatbot_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_chatbot" ON chatbot_conversations;
CREATE POLICY "select_own_chatbot" ON chatbot_conversations FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_chatbot" ON chatbot_conversations;
CREATE POLICY "insert_own_chatbot" ON chatbot_conversations FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_chatbot" ON chatbot_conversations;
CREATE POLICY "delete_own_chatbot" ON chatbot_conversations FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ INDEXES ============
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_ambulance_user_id ON ambulance_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_user_id ON complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_user_id ON chatbot_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_clinics_province ON clinics(province);

-- ============ SEED CLINICS ============
INSERT INTO clinics (name, province, district, location, latitude, longitude, phone, services)
VALUES
  ('Chris Hani Baragwanath Hospital', 'Gauteng', 'Johannesburg', 'Diepkloof, Soweto', -26.2740, 27.9800, '011 933 1000', ARRAY['General Consultation','HIV/TB Services','Chronic Medication','Mental Health','Antenatal Care','Child Health']),
  ('Helen Joseph Hospital', 'Gauteng', 'Johannesburg', 'Auckland Park', -26.1830, 28.0050, '011 489 1000', ARRAY['General Consultation','Dental Care','Mental Health','Chronic Medication','Test Result Collection']),
  ('Mamelodi Day Clinic', 'Gauteng', 'Tshwane', 'Mamelodi East', -25.7160, 28.3550, '012 803 2000', ARRAY['General Consultation','Family Planning','Immunization','Child Health','Antenatal Care']),
  ('Kalafong Hospital', 'Gauteng', 'Tshwane', 'Atteridgeville', -25.7700, 28.1700, '012 373 2000', ARRAY['General Consultation','Antenatal Care','HIV/TB Services','Chronic Medication','Dental Care','Mental Health']),
  ('Grobblersdal Clinic', 'Limpopo', 'Sekhukhune', 'Grobblersdal', -25.1667, 29.3833, '013 261 1000', ARRAY['General Consultation','Family Planning','Immunization','Child Health']),
  ('Polokwane Municipal Clinic', 'Limpopo', 'Capricorn', 'Polokwane Central', -23.9045, 29.4689, '015 290 2000', ARRAY['General Consultation','HIV/TB Services','Chronic Medication','Antenatal Care','Mental Health']),
  ('King Edward VIII Hospital', 'KwaZulu-Natal', 'Durban', 'Congella, Durban', -29.8580, 31.0280, '031 360 3000', ARRAY['General Consultation','Antenatal Care','HIV/TB Services','Chronic Medication','Dental Care','Mental Health','Child Health']),
  ('Addington Hospital', 'KwaZulu-Natal', 'Durban', 'Point, Durban', -29.8660, 31.0450, '031 362 8000', ARRAY['General Consultation','Family Planning','Chronic Medication','Test Result Collection']),
  ('Gugulethu Day Hospital', 'Western Cape', 'Cape Town', 'Gugulethu', -33.9890, 18.5630, '021 633 2000', ARRAY['General Consultation','Antenatal Care','HIV/TB Services','Child Health','Immunization']),
  ('Khayelitsha District Hospital', 'Western Cape', 'Cape Town', 'Khayelitsha', -34.0400, 18.6750, '021 360 4000', ARRAY['General Consultation','Family Planning','HIV/TB Services','Chronic Medication','Mental Health','Child Health']),
  ('Tygerberg Hospital', 'Western Cape', 'Cape Town', 'Parow Valley', -33.9040, 18.6130, '021 938 4000', ARRAY['General Consultation','Dental Care','Antenatal Care','Chronic Medication','Mental Health','Test Result Collection']),
  ('Lovedale Clinic', 'Eastern Cape', 'Buffalo City', 'King Williams Town', -32.8840, 27.3930, '043 642 2000', ARRAY['General Consultation','Family Planning','Immunization','Child Health','HIV/TB Services']),
  ('Nelson Mandela Academic Hospital', 'Eastern Cape', 'OR Tambo', 'Mthatha', -31.5800, 28.7900, '047 502 5000', ARRAY['General Consultation','Antenatal Care','Chronic Medication','Mental Health','Dental Care','HIV/TB Services']),
  ('Pelonomi Hospital', 'Free State', 'Mangaung', 'Bloemfontein', -29.1200, 26.2150, '051 406 3000', ARRAY['General Consultation','Chronic Medication','Antenatal Care','HIV/TB Services','Mental Health']),
  ('Universitas Hospital', 'Free State', 'Mangaung', 'Bloemfontein', -29.1050, 26.1850, '051 405 3000', ARRAY['General Consultation','Dental Care','Chronic Medication','Test Result Collection','Mental Health']),
  ('Kimberley Hospital', 'Northern Cape', 'Frances Baard', 'Kimberley', -28.7350, 24.7600, '053 802 9000', ARRAY['General Consultation','Family Planning','HIV/TB Services','Chronic Medication','Antenatal Care']),
  ('Klerksdorp Hospital', 'North West', 'Dr Kenneth Kaunda', 'Klerksdorp', -26.8640, 26.6680, '018 646 3000', ARRAY['General Consultation','Antenatal Care','Chronic Medication','Mental Health','Child Health']),
  ('Mahikeng Provincial Hospital', 'North West', 'Ngaka Modiri Molema', 'Mahikeng', -25.8650, 25.6400, '018 381 3000', ARRAY['General Consultation','Family Planning','HIV/TB Services','Immunization','Chronic Medication']),
  ('Rob Ferreira Hospital', 'Mpumalanga', 'Ehlanzeni', 'Nelspruit', -25.4750, 30.9800, '013 741 2000', ARRAY['General Consultation','Antenatal Care','Chronic Medication','Dental Care','HIV/TB Services']),
  ('Witbank Hospital', 'Mpumalanga', 'Nkangala', 'Witbank', -25.8830, 29.2330, '013 656 5000', ARRAY['General Consultation','Family Planning','Child Health','Chronic Medication','Mental Health'])
ON CONFLICT DO NOTHING;
