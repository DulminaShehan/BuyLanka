import { supabase } from '../lib/supabaseClient'
import { Delivery, DeliveryStatus, RiderWithProfile, OrderWithDetails } from '../types'

export interface DeliveryWithDetails extends Delivery {
  rider?: RiderWithProfile
  order?: OrderWithDetails
}

export const deliveriesService = {
  async getDeliveries(statusFilter?: string): Promise<DeliveryWithDetails[]> {
    try {
      let query = supabase.from('deliveries').select(`
        *,
        rider:riders!rider_id(
          *,
          profile:profiles!id(*)
        ),
        order:orders!order_id(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('delivery_status', statusFilter as DeliveryStatus)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching deliveries:', err)
      return []
    }
  },

  async assignRider(deliveryId: string, riderId: string, _riderProfile?: any): Promise<void> {
    const { error } = await supabase
      .from('deliveries')
      .update({
        rider_id: riderId,
        delivery_status: 'assigned',
        assigned_at: new Date().toISOString(),
      })
      .eq('id', deliveryId)

    if (error) throw error
  },

  async updateDeliveryStatus(deliveryId: string, delivery_status: DeliveryStatus): Promise<void> {
    const updates: any = { delivery_status }
    if (delivery_status === 'picked_up') updates.picked_up_at = new Date().toISOString()
    if (delivery_status === 'delivered') updates.delivered_at = new Date().toISOString()

    const { error } = await supabase.from('deliveries').update(updates).eq('id', deliveryId)
    if (error) throw error
  },
}
