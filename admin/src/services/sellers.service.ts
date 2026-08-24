import { supabase } from '../lib/supabaseClient'
import { SellerWithProfile, SellerVerificationStatus } from '../types'

export const sellersService = {
  async getSellers(search?: string, statusFilter?: string): Promise<SellerWithProfile[]> {
    try {
      let query = supabase.from('sellers').select(`
        *,
        profile:profiles!id(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('verification_status', statusFilter as SellerVerificationStatus)
      }

      if (search) {
        query = query.or(`business_name.ilike.%${search}%,nic_number.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching sellers:', err)
      return []
    }
  },

  async createSeller(payload: {
    fullName: string
    email: string
    phoneNumber: string
    businessName: string
    businessRegistrationNumber?: string
    nicNumber: string
    commissionRate?: number
    bankName?: string
    bankAccountNumber?: string
    bankBranch?: string
  }): Promise<SellerWithProfile> {
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
          role: 'seller',
          status: 'active',
        })
        .select()
        .single()

      if (profileError) {
        if (profileError.code === '23505' || profileError.message.includes('profiles_email_key')) {
          throw new Error(`A user with email "${trimmedEmail}" is already registered.`)
        }
        console.error('Error creating seller profile:', profileError)
        throw new Error(profileError.message || 'Failed to create seller profile record')
      }

      profileId = newProfile.id
    } else {
      // Update existing profile to seller role
      await supabase
        .from('profiles')
        .update({
          full_name: payload.fullName.trim(),
          phone_number: payload.phoneNumber.trim(),
          role: 'seller',
          status: 'active',
        })
        .eq('id', profileId)
    }

    // 2. Upsert Seller details record
    const { data: sellerData, error: sellerError } = await supabase
      .from('sellers')
      .upsert({
        id: profileId,
        business_name: payload.businessName.trim(),
        business_registration_number: payload.businessRegistrationNumber?.trim() || null,
        nic_number: payload.nicNumber.trim(),
        verification_status: 'verified',
        commission_rate: payload.commissionRate || 10.0,
        bank_name: payload.bankName || null,
        bank_account_number: payload.bankAccountNumber?.trim() || null,
        bank_branch: payload.bankBranch?.trim() || null,
      })
      .select(`
        *,
        profile:profiles!id(*)
      `)
      .single()

    if (sellerError) {
      console.error('Error creating/updating seller record:', sellerError)
      throw new Error(sellerError.message || 'Failed to save seller details')
    }

    return sellerData as any
  },

  async updateVerificationStatus(
    id: string,
    verification_status: SellerVerificationStatus,
    commission_rate?: number
  ): Promise<void> {
    const updates: any = { verification_status }
    if (commission_rate !== undefined) updates.commission_rate = commission_rate

    const { error } = await supabase.from('sellers').update(updates).eq('id', id)
    if (error) throw error
  },

  async deleteSeller(id: string): Promise<void> {
    // 1. Delete seller shops and products (if not automatically cascaded)
    try {
      await supabase.from('shops').delete().eq('seller_id', id)
    } catch (err) {
      console.warn('Notice when deleting associated shops:', err)
    }

    // 2. Delete from sellers table
    const { error: sellerError } = await supabase.from('sellers').delete().eq('id', id)
    if (sellerError) {
      console.error('Error deleting seller record:', sellerError)
      throw new Error(sellerError.message || 'Failed to delete seller record')
    }

    // 3. Delete from profiles table or reset profile role to customer
    try {
      await supabase.from('profiles').delete().eq('id', id)
    } catch (profileErr) {
      console.warn('Notice when cleaning profile for deleted seller:', profileErr)
    }
  },
}
