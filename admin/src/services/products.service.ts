import { supabase } from '../lib/supabaseClient'
import { ProductWithShopAndCategory, ProductStatus } from '../types'

export const productsService = {
  async getProducts(search?: string, statusFilter?: string): Promise<ProductWithShopAndCategory[]> {
    try {
      let query = supabase.from('products').select(`
        *,
        shop:shops!shop_id(*),
        category:categories!category_id(*)
      `)

      if (statusFilter && statusFilter !== 'all') {
        query = query.eq('status', statusFilter as ProductStatus)
      }

      if (search) {
        query = query.or(`title.ilike.%${search}%,sku.ilike.%${search}%`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      if (error) throw error
      return (data as any) || []
    } catch (err) {
      console.error('Error fetching products:', err)
      return []
    }
  },

  async updateProductStatus(id: string, status: ProductStatus): Promise<void> {
    const { error } = await supabase.from('products').update({ status }).eq('id', id)
    if (error) throw error
  },

  async deleteProduct(id: string): Promise<void> {
    const { error } = await supabase.from('products').delete().eq('id', id)
    if (error) throw error
  },
}
