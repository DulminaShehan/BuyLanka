import { supabase } from '../lib/supabaseClient'
import { RiderWithProfile, RiderVerificationStatus, RiderVehicleType } from '../types'

export const ridersService = {
  async getRiders(search?: string, statusFilter?: string): Promise<RiderWithProfile[]> {
    try {
      let query = supabase.from('riders').select(`
        *,
        profile:profiles!id(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('verification_status', statusFilter as RiderVerificationStatus)
      }

      if (search) {
        query = query.or(`vehicle_number.ilike.%${search}%,assigned_zone.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching riders:', err)
      return []
    }
  },

  async createRider(payload: {
    fullName: string
    email: string
    phoneNumber: string
    vehicleType: RiderVehicleType
    vehicleNumber: string
    drivingLicenseNumber: string
    assignedZone: string
  }): Promise<RiderWithProfile> {
    const trimmedEmail = payload.email.trim().toLowerCase()

    // 1. Check if profile with this email already exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id, email, role, status')
      .eq('email', trimmedEmail)
      .maybeSingle()

    let profileId = existingProfile?.id

    if (!profileId) {
      profileId = crypto.randomUUID()
      const { data: newProfile, error: profileError } = await supabase
        .from('profiles')
        .insert({
          id: profileId,
          full_name: payload.fullName.trim(),
          email: trimmedEmail,
          phone_number: payload.phoneNumber.trim(),
          role: 'rider',
          status: 'active',
        })
        .select()
        .single()

      if (profileError) {
        if (profileError.code === '23505' || profileError.message.includes('profiles_email_key')) {
          throw new Error(`A user with email "${trimmedEmail}" is already registered.`)
        }
        console.error('Error creating rider profile:', profileError)
        throw new Error(profileError.message || 'Failed to create rider profile record')
      }

      profileId = newProfile.id
    } else {
      await supabase
        .from('profiles')
        .update({
          full_name: payload.fullName.trim(),
          phone_number: payload.phoneNumber.trim(),
          role: 'rider',
          status: 'active',
        })
        .eq('id', profileId)
    }

    // 2. Upsert Rider details record
    const { data: riderData, error: riderError } = await supabase
      .from('riders')
      .upsert({
        id: profileId,
        vehicle_type: payload.vehicleType,
        vehicle_number: payload.vehicleNumber.trim(),
        driving_license_number: payload.drivingLicenseNumber.trim(),
        assigned_zone: payload.assignedZone.trim(),
        availability_status: 'available',
        verification_status: 'approved',
      })
      .select(`
        *,
        profile:profiles!id(*)
      `)
      .single()

    if (riderError) {
      console.error('Error creating/updating rider record:', riderError)
      throw new Error(riderError.message || 'Failed to save rider details')
    }

    return riderData as any
  },

  async updateRiderStatus(id: string, verification_status: RiderVerificationStatus): Promise<void> {
    const { error } = await supabase.from('riders').update({ verification_status }).eq('id', id)
    if (error) throw error
  },

  async updateRiderZone(id: string, assigned_zone: string): Promise<void> {
    const { error } = await supabase.from('riders').update({ assigned_zone }).eq('id', id)
    if (error) throw error
  },

  async deleteRider(id: string): Promise<void> {
    // 1. Unassign any pending or active deliveries currently tied to this rider
    try {
      await supabase
        .from('deliveries')
        .update({ rider_id: null, delivery_status: 'unassigned' })
        .eq('rider_id', id)
    } catch (err) {
      console.warn('Notice when unassigning deliveries for deleted rider:', err)
    }

    // 2. Delete from riders table
    const { error: riderError } = await supabase.from('riders').delete().eq('id', id)
    if (riderError) {
      console.error('Error deleting rider record:', riderError)
      throw new Error(riderError.message || 'Failed to delete rider record')
    }

    // 3. Delete from profiles table
    try {
      await supabase.from('profiles').delete().eq('id', id)
    } catch (profileErr) {
      console.warn('Notice when cleaning profile for deleted rider:', profileErr)
    }
  },
}
