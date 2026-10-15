-- POPIA compliance: lock down all tables to authenticated-only, remove anon access,
-- and narrow column privileges so patients can only modify their own data, not
-- privileged columns like appointment status, reference numbers, or audit fields.

-- 1. Revoke ALL privileges from anon on every patient-data table
REVOKE ALL ON profiles FROM anon;
REVOKE ALL ON appointments FROM anon;
REVOKE ALL ON ambulance_requests FROM anon;
REVOKE ALL ON activities FROM anon;
REVOKE ALL ON notifications FROM anon;
REVOKE ALL ON complaints FROM anon;
REVOKE ALL ON chatbot_conversations FROM anon;

-- 2. Clinics: public read for authenticated, no writes from client
REVOKE ALL ON clinics FROM anon;
REVOKE INSERT, UPDATE, DELETE ON clinics FROM authenticated;
GRANT SELECT ON clinics TO authenticated;

-- 3. Profiles: patients can update their own info columns but NOT privileged columns
REVOKE UPDATE ON profiles FROM authenticated;
GRANT UPDATE (
  full_name, id_number, date_of_birth, gender, mobile_number, email,
  home_address, blood_type, allergies, chronic_conditions,
  emergency_contact_name, emergency_contact_phone, language_preference,
  notification_preferences, updated_at
) ON profiles TO authenticated;

REVOKE INSERT ON profiles FROM authenticated;
GRANT INSERT (id, full_name, email) ON profiles TO authenticated;

-- 4. Appointments: patients insert their own, but NOT status/reference_number/audit columns
REVOKE INSERT ON appointments FROM authenticated;
GRANT INSERT (
  user_id, clinic_id, full_name, id_number, date_of_birth, gender,
  mobile_number, email, home_address, service, preferred_date, preferred_time,
  alternative_date, appointment_type, reason_for_visit, symptoms,
  existing_conditions, current_medication, additional_notes,
  consent_accuracy, consent_share, consent_notifications
) ON appointments TO authenticated;

-- Patients can only update consent fields, not status or reference
REVOKE UPDATE ON appointments FROM authenticated;
GRANT UPDATE (
  consent_accuracy, consent_share, consent_notifications
) ON appointments TO authenticated;

-- 5. Ambulance requests: patients insert, but status/estimated_arrival is server-controlled
REVOKE INSERT ON ambulance_requests FROM authenticated;
GRANT INSERT (
  user_id, patient_name, patient_condition, emergency_contact_name,
  emergency_contact_phone, location_lat, location_lng, location_address
) ON ambulance_requests TO authenticated;

REVOKE UPDATE ON ambulance_requests FROM authenticated;

-- 6. Notifications: patients can only update is_read, nothing else
REVOKE UPDATE ON notifications FROM authenticated;
GRANT UPDATE (is_read) ON notifications TO authenticated;

-- 7. Activities: patients insert their own activity log, no updates
REVOKE UPDATE ON activities FROM authenticated;

-- 8. Complaints: patients insert and update their own, but NOT status/priority/reference
REVOKE INSERT ON complaints FROM authenticated;
GRANT INSERT (
  user_id, type, subject, message
) ON complaints TO authenticated;

REVOKE UPDATE ON complaints FROM authenticated;
GRANT UPDATE (subject, message, updated_at) ON complaints TO authenticated;

-- 9. Chatbot conversations: patients insert and select their own
-- Missing UPDATE policy - add it for completeness
CREATE POLICY "update_own_chatbot" ON chatbot_conversations FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. Ensure user_id defaults to auth.uid() where the client shouldn't set it
ALTER TABLE appointments ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE ambulance_requests ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE activities ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE notifications ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE complaints ALTER COLUMN user_id SET DEFAULT auth.uid();

-- 11. Add consent tracking columns to profiles for POPIA
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS consent_popia BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS consent_popia_at TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS consent_marketing BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS data_retention_preference TEXT DEFAULT 'standard';

-- Grant update on the new consent columns
GRANT UPDATE (consent_popia, consent_popia_at, consent_marketing, data_retention_preference, updated_at) ON profiles TO authenticated;
