import { supabase } from '../lib/supabaseClient'
import { Profile, UserStatus } from '../types'

export type CustomerWithStats = Profile & { orders_count?: number; total_spent?: number }

export const customersService = {
  async getCustomers(search?: string, statusFilter?: string): Promise<CustomerWithStats[]> {
    try {
      let query = supabase.from('profiles').select('*').eq('role', 'customer')

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('status', statusFilter as UserStatus)
      }

      if (search) {
        query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,phone_number.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as CustomerWithStats[]) || []
    } catch (err) {
      console.error('Error fetching customers:', err)
      return []
    }
  },

  async updateCustomerStatus(id: string, status: UserStatus): Promise<void> {
    const { error } = await supabase.from('profiles').update({ status }).eq('id', id)
    if (error) throw error
  },
}
