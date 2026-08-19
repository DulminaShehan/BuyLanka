import { Database } from './database.types'

export * from './database.types'

export type Profile = Database['public']['Tables']['profiles']['Row']
export type Seller = Database['public']['Tables']['sellers']['Row']
export type Shop = Database['public']['Tables']['shops']['Row']
export type Rider = Database['public']['Tables']['riders']['Row']
export type Category = Database['public']['Tables']['categories']['Row']
export type Product = Database['public']['Tables']['products']['Row']
export type Order = Database['public']['Tables']['orders']['Row']
export type OrderItem = Database['public']['Tables']['order_items']['Row']
export type Delivery = Database['public']['Tables']['deliveries']['Row']
export type PlatformSetting = Database['public']['Tables']['platform_settings']['Row']

// Extended / Join Types for UI
export interface ShopWithSeller extends Shop {
  seller?: Seller & { profile?: Profile }
}

export interface ProductWithShopAndCategory extends Product {
  shop?: Shop
  category?: Category
}

export interface OrderWithDetails extends Order {
  customer?: Profile
  shop?: Shop
  items?: OrderItem[]
  delivery?: Delivery & { rider?: Rider & { profile?: Profile } }
}

export interface SellerWithProfile extends Seller {
  profile: Profile
  shops?: Shop[]
}

export interface RiderWithProfile extends Rider {
  profile: Profile
  deliveries_count?: number
}

export interface DashboardMetrics {
  totalRevenue: number
  totalOrders: number
  totalCustomers: number
  totalSellers: number
  totalRiders: number
  pendingApprovals: {
    shops: number
    products: number
    sellers: number
    riders: number
  }
  recentOrders: OrderWithDetails[]
  salesTrend: {
    date: string
    revenue: number
    orders: number
  }[]
}
