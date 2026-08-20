import { supabase } from '../lib/supabaseClient'
import { Profile } from '../types'

export interface AuthState {
  user: Profile | null
  session: any | null
  isLoading: boolean
  isAdmin: boolean
}

export const authService = {
  async getCurrentProfile(userId: string): Promise<Profile | null> {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle()

      if (error || !data) {
        return null
      }

      return data as Profile
    } catch (err) {
      console.error('Exception fetching profile:', err)
      return null
    }
  },

  async signIn(email: string, password: string): Promise<{ profile: Profile | null; error: string | null }> {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error || !data.user) {
        return { profile: null, error: error?.message || 'Invalid email or password' }
      }

      let profile = await this.getCurrentProfile(data.user.id)

      // If auth succeeded but profile is missing from public.profiles table, automatically create it as admin
      if (!profile) {
        try {
          const { data: newProfile } = await supabase
            .from('profiles')
            .upsert({
              id: data.user.id,
              email: data.user.email || email,
              full_name: data.user.user_metadata?.full_name || 'Admin User',
              role: 'admin',
              status: 'active',
            })
            .select()
            .maybeSingle()

          if (newProfile) {
            profile = newProfile as Profile
          }
        } catch (profileErr) {
          console.warn('Could not auto-create profile:', profileErr)
        }
      }

      // If profile exists or fallback is needed
      if (!profile) {
        // Construct standard admin profile in memory for valid authenticated session
        profile = {
          id: data.user.id,
          email: data.user.email || email,
          full_name: 'Administrator',
          phone_number: null,
          role: 'admin',
          status: 'active',
          avatar_url: null,
          created_at: data.user.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }
      }

      if (profile.role !== 'admin') {
        await supabase.auth.signOut()
        return { profile: null, error: 'Access denied: this account does not have administrator role.' }
      }

      if (profile.status !== 'active') {
        await supabase.auth.signOut()
        return { profile: null, error: 'Administrator account is suspended or inactive.' }
      }

      return { profile, error: null }
    } catch (err: any) {
      return { profile: null, error: err.message || 'An unexpected error occurred during login.' }
    }
  },

  async signUp(email: string, password: string, fullName?: string): Promise<{ profile: Profile | null; error: string | null }> {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName || 'Admin User',
            role: 'admin',
          },
        },
      })

      if (error) {
        return { profile: null, error: error.message }
      }

      if (!data.user) {
        return { profile: null, error: 'Failed to create account.' }
      }

      // Create admin profile
      try {
        const { data: newProfile } = await supabase
          .from('profiles')
          .upsert(
            {
              id: data.user.id,
              email: email.trim().toLowerCase(),
              full_name: fullName?.trim() || 'Admin User',
              role: 'admin',
              status: 'active',
            },
            { onConflict: 'email' }
          )
          .select()
          .maybeSingle()

        if (newProfile) {
          return { profile: newProfile as Profile, error: null }
        }
      } catch (profErr) {
        console.warn('Profile table insert warning:', profErr)
      }

      const fallbackProfile: Profile = {
        id: data.user.id,
        email,
        full_name: fullName || 'Admin User',
        phone_number: null,
        role: 'admin',
        status: 'active',
        avatar_url: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }

      return { profile: fallbackProfile, error: null }
    } catch (err: any) {
      return { profile: null, error: err.message || 'Registration failed' }
    }
  },

  async signOut(): Promise<void> {
    await supabase.auth.signOut()
  },

  async getInitialSession(): Promise<{ profile: Profile | null; session: any | null }> {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session?.user) {
        return { profile: null, session: null }
      }

      let profile = await this.getCurrentProfile(session.user.id)
      if (!profile) {
        profile = {
          id: session.user.id,
          email: session.user.email || '',
          full_name: session.user.user_metadata?.full_name || 'Administrator',
          phone_number: null,
          role: 'admin',
          status: 'active',
          avatar_url: null,
          created_at: session.user.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }
      }

      return { profile, session }
    } catch (err) {
      console.error('Error checking initial session:', err)
      return { profile: null, session: null }
    }
  },
}
