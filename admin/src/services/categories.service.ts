import { supabase } from '../lib/supabaseClient'
import { Category } from '../types'
import { slugify } from '../utils/formatters'

export const categoriesService = {
  async getCategories(search?: string): Promise<Category[]> {
    try {
      let query = supabase.from('categories').select('*').order('display_order', { ascending: true })

      if (search) {
        query = query.ilike('name', `%${search}%`)
      }

      const { data, error } = await query
      if (error) throw error
      return (data as Category[]) || []
    } catch (err) {
      console.error('Error fetching categories:', err)
      return []
    }
  },

  async createCategory(payload: {
    name: string
    description?: string
    icon?: string
    image_url?: string
    parent_id?: string | null
    is_active?: boolean
    display_order?: number
  }): Promise<Category> {
    const slug = slugify(payload.name)

    const { data, error } = await supabase
      .from('categories')
      .insert({
        name: payload.name,
        slug,
        description: payload.description || null,
        icon: payload.icon || null,
        image_url: payload.image_url || null,
        parent_id: payload.parent_id || null,
        is_active: payload.is_active !== undefined ? payload.is_active : true,
        display_order: payload.display_order || 0,
      })
      .select()
      .single()

    if (error) throw error
    return data as Category
  },

  async updateCategory(id: string, updates: Partial<Category>): Promise<Category> {
    const { data, error } = await supabase
      .from('categories')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data as Category
  },

  async deleteCategory(id: string): Promise<void> {
    const { error } = await supabase.from('categories').delete().eq('id', id)
    if (error) throw error
  },
}
