import { supabase } from '../lib/supabaseClient'
import { RiderWithProfile, RiderVerificationStatus, RiderVehicleType } from '../types'

export const ridersService = {
  async getRiders(search?: string, statusFilter?: string): Promise<RiderWithProfile[]> {
    try {
      let query = supabase.from('riders').select(`
        *,
        profile:profiles!id(*),
        pending_change_requests:rider_profile_change_requests(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        if (statusFilter === 'pending_update') {
          query = query.eq('profile_update_status', 'pending_review')
        } else {
          query = query.eq('verification_status', statusFilter as RiderVerificationStatus)
        }
      }

      if (search) {
        query = query.or(`vehicle_number.ilike.%${search}%,assigned_zone.ilike.%${search}%,vehicle_model.ilike.%${search}%`)
      }

      const { data, error } = await query.order('updated_at', { ascending: false })
      if (error) {
        // Fallback without change_requests in case migration is still pending on remote db
        const fallbackQuery = await supabase.from('riders').select(`
          *,
          profile:profiles!id(*)
        `).order('created_at', { ascending: false })
        if (fallbackQuery.error) throw fallbackQuery.error
        return (fallbackQuery.data as any) || []
      }
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

  /// Approve sensitive rider profile change request
  async approveChangeRequest(requestId: string, riderId: string, requestedChanges: Record<string, any>, adminId?: string): Promise<void> {
    try {
      const { error: rpcError } = await supabase.rpc('approve_rider_profile_change_request', {
        p_request_id: requestId,
        p_admin_id: adminId || null,
      })

      if (rpcError) {
        // Fallback to direct table updates if RPC is not installed
        await supabase
          .from('rider_profile_change_requests')
          .update({
            status: 'approved',
            reviewed_by: adminId || null,
            reviewed_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id', requestId)

        const riderUpdates: Record<string, any> = {
          profile_update_status: 'approved',
          updated_at: new Date().toISOString(),
        }
        if (requestedChanges.vehicle_number) riderUpdates.vehicle_number = requestedChanges.vehicle_number
        if (requestedChanges.driving_license_number) riderUpdates.driving_license_number = requestedChanges.driving_license_number
        if (requestedChanges.vehicle_type) riderUpdates.vehicle_type = requestedChanges.vehicle_type
        if (requestedChanges.vehicle_model) riderUpdates.vehicle_model = requestedChanges.vehicle_model
        if (requestedChanges.vehicle_color) riderUpdates.vehicle_color = requestedChanges.vehicle_color

        await supabase.from('riders').update(riderUpdates).eq('id', riderId)
      }
    } catch (err) {
      console.error('Error approving change request:', err)
      throw err
    }
  },

  /// Reject sensitive rider profile change request with admin remarks
  async rejectChangeRequest(requestId: string, riderId: string, remarks: string, adminId?: string): Promise<void> {
    try {
      const { error: rpcError } = await supabase.rpc('reject_rider_profile_change_request', {
        p_request_id: requestId,
        p_admin_id: adminId || null,
        p_remarks: remarks,
      })

      if (rpcError) {
        // Fallback to direct table updates
        await supabase
          .from('rider_profile_change_requests')
          .update({
            status: 'rejected',
            admin_remarks: remarks,
            reviewed_by: adminId || null,
            reviewed_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id', requestId)

        await supabase
          .from('riders')
          .update({
            profile_update_status: 'rejected',
            updated_at: new Date().toISOString(),
          })
          .eq('id', riderId)
      }
    } catch (err) {
      console.error('Error rejecting change request:', err)
      throw err
    }
  },

  /// Real-time subscription to rider profile updates & change requests
  subscribeToRiders(onChange: () => void): () => void {
    const channel = supabase
      .channel('admin-rider-sync-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'riders' }, () => {
        onChange()
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        onChange()
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rider_profile_change_requests' }, () => {
        onChange()
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },
}
