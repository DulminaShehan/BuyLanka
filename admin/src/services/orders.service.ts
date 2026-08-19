import { supabase } from '../lib/supabaseClient'
import { OrderWithDetails, OrderStatus } from '../types'

export const ordersService = {
  async getOrders(search?: string, statusFilter?: string): Promise<OrderWithDetails[]> {
    try {
      let query = supabase.from('orders').select(`
        *,
        customer:profiles!customer_id(*),
        shop:shops!shop_id(*),
        items:order_items!order_id(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('order_status', statusFilter as OrderStatus)
      }

      if (search) {
        query = query.ilike('order_number', `%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching orders:', err)
      return []
    }
  },

  async updateOrderStatus(id: string, order_status: OrderStatus): Promise<void> {
    const { error } = await supabase.from('orders').update({ order_status }).eq('id', id)
    if (error) throw error
  },
}
