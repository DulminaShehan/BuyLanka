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
    const newProfileId = crypto.randomUUID()

    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: newProfileId,
        full_name: payload.fullName,
        email: payload.email,
        phone_number: payload.phoneNumber,
        role: 'rider',
        status: 'active',
      })
      .select()
      .single()

    if (profileError) {
      console.error('Error creating rider profile:', profileError)
      throw new Error(profileError.message || 'Failed to create rider profile record')
    }

    const { data: riderData, error: riderError } = await supabase
      .from('riders')
      .insert({
        id: profileData.id,
        vehicle_type: payload.vehicleType,
        vehicle_number: payload.vehicleNumber,
        driving_license_number: payload.drivingLicenseNumber,
        assigned_zone: payload.assignedZone,
        availability_status: 'available',
        verification_status: 'approved',
      })
      .select(`
        *,
        profile:profiles!id(*)
      `)
      .single()

    if (riderError) {
      console.error('Error creating rider record:', riderError)
      throw new Error(riderError.message || 'Failed to create rider record')
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
}
