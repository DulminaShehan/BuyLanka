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
    const newProfileId = crypto.randomUUID()

    // 1. Create Profile record for the seller
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: newProfileId,
        full_name: payload.fullName,
        email: payload.email,
        phone_number: payload.phoneNumber,
        role: 'seller',
        status: 'active',
      })
      .select()
      .single()

    if (profileError) {
      console.error('Error creating seller profile:', profileError)
      throw new Error(profileError.message || 'Failed to create seller profile record')
    }

    // 2. Create Seller details record
    const { data: sellerData, error: sellerError } = await supabase
      .from('sellers')
      .insert({
        id: profileData.id,
        business_name: payload.businessName,
        business_registration_number: payload.businessRegistrationNumber || null,
        nic_number: payload.nicNumber,
        verification_status: 'verified',
        commission_rate: payload.commissionRate || 10.0,
        bank_name: payload.bankName || null,
        bank_account_number: payload.bankAccountNumber || null,
        bank_branch: payload.bankBranch || null,
      })
      .select(`
        *,
        profile:profiles!id(*)
      `)
      .single()

    if (sellerError) {
      console.error('Error creating seller record:', sellerError)
      throw new Error(sellerError.message || 'Failed to create seller record')
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
}
