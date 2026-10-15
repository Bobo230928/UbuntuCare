export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export interface Profile {
  id: string;
  full_name: string;
  id_number: string;
  date_of_birth: string | null;
  gender: string;
  mobile_number: string;
  email: string;
  home_address: string;
  blood_type: string;
  allergies: string;
  chronic_conditions: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
  language_preference: string;
  notification_preferences: { sms: boolean; email: boolean; push: boolean };
  consent_popia: boolean;
  consent_popia_at: string | null;
  consent_marketing: boolean;
  data_retention_preference: string;
  created_at: string;
  updated_at: string;
}

export interface Clinic {
  id: string;
  name: string;
  province: string;
  district: string;
  location: string;
  latitude: number | null;
  longitude: number | null;
  operating_hours: { mon_fri: string; sat: string; sun: string };
  phone: string;
  services: string[];
  created_at: string;
}

export interface Appointment {
  id: string;
  user_id: string;
  clinic_id: string | null;
  clinic?: Clinic;
  full_name: string;
  id_number: string;
  date_of_birth: string | null;
  gender: string;
  mobile_number: string;
  email: string;
  home_address: string;
  service: string;
  preferred_date: string;
  preferred_time: string;
  alternative_date: string | null;
  appointment_type: string;
  reason_for_visit: string;
  symptoms: string;
  existing_conditions: string;
  current_medication: string;
  additional_notes: string;
  consent_accuracy: boolean;
  consent_share: boolean;
  consent_notifications: boolean;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'rescheduled';
  reference_number: string | null;
  created_at: string;
}

export interface AmbulanceRequest {
  id: string;
  user_id: string;
  patient_name: string;
  patient_condition: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
  location_lat: number | null;
  location_lng: number | null;
  location_address: string;
  status: 'requested' | 'dispatched' | 'en_route' | 'arrived' | 'completed' | 'cancelled';
  estimated_arrival_minutes: number;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  type: 'appointment_reminder' | 'test_result' | 'clinic_announcement' | 'ambulance_update' | 'complaint_update';
  title: string;
  message: string;
  is_read: boolean;
  created_at: string;
}

export interface Activity {
  id: string;
  user_id: string;
  type: 'search' | 'booking' | 'cancellation' | 'reschedule' | 'ambulance_request' | 'profile_update' | 'complaint';
  description: string;
  metadata: Json;
  created_at: string;
}

export interface Complaint {
  id: string;
  user_id: string;
  type: 'complaint' | 'feedback';
  subject: string;
  message: string;
  reference_number: string | null;
  status: 'pending' | 'in_review' | 'resolved' | 'escalated';
  priority: 'normal' | 'urgent';
  created_at: string;
  updated_at: string;
}
