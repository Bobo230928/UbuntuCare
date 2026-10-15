import { type ReactNode, createContext, useContext, useEffect, useState } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';
import type { Profile } from '@/lib/types';

interface AuthContextValue {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

async function getOrCreateProfile(user: User): Promise<Profile | null> {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle();
  if (error) return null;
  if (data) return data as Profile;

  const fullName = typeof user.user_metadata?.full_name === 'string' ? user.user_metadata.full_name : '';
  const { data: created, error: createError } = await supabase.from('profiles').upsert({
    id: user.id,
    full_name: fullName,
    email: user.email ?? '',
    consent_popia: false,
    consent_marketing: false,
    data_retention_preference: 'standard',
  }).select('*').maybeSingle();
  return createError ? null : created as Profile | null;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshProfile = async () => {
    const currentUser = session?.user;
    if (currentUser) setProfile(await getOrCreateProfile(currentUser));
  };

  useEffect(() => {
    let mounted = true;

    const loadSession = async () => {
      const { data } = await supabase.auth.getSession();
      if (!mounted) return;
      setSession(data.session);
      if (data.session?.user) setProfile(await getOrCreateProfile(data.session.user));
      if (mounted) setLoading(false);
    };

    void loadSession();

    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (nextSession?.user) {
        void getOrCreateProfile(nextSession.user).then(nextProfile => {
          if (mounted) setProfile(nextProfile);
        });
      } else {
        setProfile(null);
      }
      setLoading(false);
    });

    return () => {
      mounted = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return { error: error ? new Error(error.message) : null };
  };

  const signUp = async (email: string, password: string, fullName: string) => {
    const { data, error } = await supabase.auth.signUp({ email, password, options: { data: { full_name: fullName } } });
    if (error) return { error: new Error(error.message) };
    if (data.user) {
      const { error: profileError } = await supabase.from('profiles').upsert({ id: data.user.id, full_name: fullName, email }).select('*').maybeSingle();
      if (profileError) return { error: new Error(profileError.message) };
      setProfile(await getOrCreateProfile(data.user));
    }
    return { error: null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setProfile(null);
  };

  return <AuthContext.Provider value={{ user: session?.user ?? null, session, profile, loading, signIn, signUp, signOut, refreshProfile }}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
