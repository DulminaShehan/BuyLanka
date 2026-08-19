import { supabase } from '../lib/supabaseClient'
import { ShopWithSeller, ShopStatus } from '../types'
import { slugify } from '../utils/formatters'

export const shopsService = {
  async getShops(search?: string, statusFilter?: string): Promise<ShopWithSeller[]> {
    try {
      let query = supabase.from('shops').select(`
        *,
        seller:sellers!seller_id(
          *,
          profile:profiles!id(*)
        )
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('status', statusFilter as ShopStatus)
      }

      if (search) {
        query = query.or(`name.ilike.%${search}%,city.ilike.%${search}%,district.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching shops:', err)
      return []
    }
  },

  async updateShopStatus(id: string, status: ShopStatus): Promise<void> {
    const { error } = await supabase.from('shops').update({ status }).eq('id', id)
    if (error) throw error
  },

  async createShop(payload: {
    sellerId: string
    name: string
    description?: string
    address?: string
    city?: string
    district?: string
    contactPhone?: string
  }): Promise<ShopWithSeller> {
    const slug = slugify(payload.name)

    const { data, error } = await supabase
      .from('shops')
      .insert({
        seller_id: payload.sellerId,
        name: payload.name,
        slug,
        description: payload.description || null,
        address: payload.address || null,
        city: payload.city || null,
        district: payload.district || null,
        contact_phone: payload.contactPhone || null,
        status: 'approved',
      })
      .select(`
        *,
        seller:sellers!seller_id(
          *,
          profile:profiles!id(*)
        )
      `)
      .single()

    if (error) throw error
    return data as any
  },
}
