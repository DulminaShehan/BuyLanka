import { createClient } from '@supabase/supabase-js'
import { supabase, isSupabaseConfigured } from '../lib/supabaseClient'
import { Profile, UserStatus } from '../types'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || ''
const supabaseKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  ''

// Isolated client instance used specifically for creating accounts without hijacking active session
const isolatedAuthClient = createClient(
  supabaseUrl || 'https://placeholder-project.supabase.co',
  supabaseKey || 'placeholder-anon-key',
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  }
)

export interface CreateAdminPayload {
  fullName: string
  email: string
  password?: string
  phoneNumber?: string
  status?: UserStatus
}

export const adminsService = {
  async getAdmins(search?: string, statusFilter?: string): Promise<Profile[]> {
    try {
      let query = supabase.from('profiles').select('*').eq('role', 'admin')

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('status', statusFilter as UserStatus)
      }

      if (search) {
        query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,phone_number.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as Profile[]) || []
    } catch (err) {
      console.error('Error fetching admins:', err)
      return []
    }
  },

  async createAdmin(payload: CreateAdminPayload): Promise<Profile> {
    const trimmedEmail = payload.email.trim().toLowerCase()
    const trimmedName = payload.fullName.trim()
    const trimmedPhone = payload.phoneNumber?.trim() || null
    const status = payload.status || 'active'
    const password = payload.password || 'BuyLanka@Admin123'

    // 1. Check if an account already exists in profiles with this email
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('*')
      .eq('email', trimmedEmail)
      .maybeSingle()

    if (existingProfile) {
      // If it exists and already is an admin
      if (existingProfile.role === 'admin') {
        throw new Error(`An administrator with email "${trimmedEmail}" is already registered.`)
      }

      // Upgrade existing profile to admin role
      const { data: upgradedProfile, error: upgradeError } = await supabase
        .from('profiles')
        .update({
          full_name: trimmedName || existingProfile.full_name,
          phone_number: trimmedPhone || existingProfile.phone_number,
          role: 'admin',
          status,
          updated_at: new Date().toISOString(),
        })
        .eq('id', existingProfile.id)
        .select()
        .single()

      if (upgradeError) {
        throw new Error(upgradeError.message || 'Failed to promote existing user to administrator.')
      }

      return upgradedProfile as Profile
    }

    // 2. Register account in Supabase Auth using isolated client
    let createdAuthUserId: string | null = null
    if (isSupabaseConfigured && password) {
      try {
        const { data: authData, error: authError } = await isolatedAuthClient.auth.signUp({
          email: trimmedEmail,
          password,
          options: {
            data: {
              full_name: trimmedName,
              role: 'admin',
            },
          },
        })

        if (authError && !authError.message.includes('User already registered')) {
          console.warn('Supabase Auth signup notice:', authError.message)
        } else if (authData?.user) {
          createdAuthUserId = authData.user.id
        }
      } catch (authErr) {
        console.warn('Auth registration exception (proceeding to profile upsert):', authErr)
      }
    }

    const profileId = createdAuthUserId || crypto.randomUUID()

    // 3. Upsert profile in public.profiles table
    const { data: newProfile, error: profileError } = await supabase
      .from('profiles')
      .upsert(
        {
          id: profileId,
          full_name: trimmedName,
          email: trimmedEmail,
          phone_number: trimmedPhone,
          role: 'admin',
          status,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'email' }
      )
      .select()
      .single()

    if (profileError) {
      if (profileError.code === '23505' || profileError.message.includes('profiles_email_key')) {
        throw new Error(`An administrator with email "${trimmedEmail}" already exists.`)
      }
      throw new Error(profileError.message || 'Failed to create administrator profile record.')
    }

    return newProfile as Profile
  },

  async updateAdminStatus(id: string, status: UserStatus): Promise<void> {
    const { error } = await supabase
      .from('profiles')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)

    if (error) throw error
  },

  async updateAdmin(id: string, payload: { fullName?: string; phoneNumber?: string; status?: UserStatus }): Promise<Profile> {
    const updates: any = { updated_at: new Date().toISOString() }
    if (payload.fullName !== undefined) updates.full_name = payload.fullName.trim()
    if (payload.phoneNumber !== undefined) updates.phone_number = payload.phoneNumber.trim() || null
    if (payload.status !== undefined) updates.status = payload.status

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data as Profile
  },

  async deleteAdmin(id: string): Promise<void> {
    // Revoke admin status or remove profile
    const { error } = await supabase
      .from('profiles')
      .update({ status: 'suspended', updated_at: new Date().toISOString() })
      .eq('id', id)

    if (error) throw error
  },
}
