// PostgreSQL / Supabase Database Type Definitions for BuyLanka

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type UserRole = 'admin' | 'seller' | 'rider' | 'customer'
export type UserStatus = 'active' | 'suspended' | 'pending'
export type SellerVerificationStatus = 'pending' | 'verified' | 'rejected' | 'suspended'
export type ShopStatus = 'pending' | 'approved' | 'suspended' | 'rejected'
export type RiderVehicleType = 'motorcycle' | 'three_wheeler' | 'car' | 'van' | 'bicycle'
export type RiderAvailability = 'available' | 'busy' | 'offline'
export type RiderVerificationStatus = 'pending' | 'approved' | 'rejected' | 'suspended'
export type ProductStatus = 'pending_approval' | 'published' | 'draft' | 'rejected' | 'archived'
export type PaymentMethod = 'cod' | 'card' | 'bank_transfer' | 'koko' | 'mintpay'
export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded'
export type OrderStatus = 'pending' | 'processing' | 'ready_for_pickup' | 'shipped' | 'delivered' | 'cancelled' | 'returned'
export type DeliveryStatus = 'unassigned' | 'assigned' | 'picked_up' | 'in_transit' | 'delivered' | 'failed' | 'cancelled'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          full_name: string
          email: string
          phone_number: string | null
          role: UserRole
          status: UserStatus
          avatar_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          full_name: string
          email: string
          phone_number?: string | null
          role?: UserRole
          status?: UserStatus
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          full_name?: string
          email?: string
          phone_number?: string | null
          role?: UserRole
          status?: UserStatus
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      sellers: {
        Row: {
          id: string
          business_name: string
          business_registration_number: string | null
          nic_number: string | null
          verification_status: SellerVerificationStatus
          commission_rate: number
          bank_name: string | null
          bank_account_number: string | null
          bank_branch: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          business_name: string
          business_registration_number?: string | null
          nic_number?: string | null
          verification_status?: SellerVerificationStatus
          commission_rate?: number
          bank_name?: string | null
          bank_account_number?: string | null
          bank_branch?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          business_name?: string
          business_registration_number?: string | null
          nic_number?: string | null
          verification_status?: SellerVerificationStatus
          commission_rate?: number
          bank_name?: string | null
          bank_account_number?: string | null
          bank_branch?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      shops: {
        Row: {
          id: string
          seller_id: string
          name: string
          slug: string
          description: string | null
          logo_url: string | null
          banner_url: string | null
          address: string | null
          city: string | null
          district: string | null
          contact_phone: string | null
          status: ShopStatus
          rating: number
          total_reviews: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          seller_id: string
          name: string
          slug: string
          description?: string | null
          logo_url?: string | null
          banner_url?: string | null
          address?: string | null
          city?: string | null
          district?: string | null
          contact_phone?: string | null
          status?: ShopStatus
          rating?: number
          total_reviews?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          seller_id?: string
          name?: string
          slug?: string
          description?: string | null
          logo_url?: string | null
          banner_url?: string | null
          address?: string | null
          city?: string | null
          district?: string | null
          contact_phone?: string | null
          status?: ShopStatus
          rating?: number
          total_reviews?: number
          created_at?: string
          updated_at?: string
        }
      }
      riders: {
        Row: {
          id: string
          vehicle_type: RiderVehicleType
          vehicle_number: string
          driving_license_number: string
          assigned_zone: string | null
          availability_status: RiderAvailability
          verification_status: RiderVerificationStatus
          rating: number
          total_deliveries: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          vehicle_type: RiderVehicleType
          vehicle_number: string
          driving_license_number: string
          assigned_zone?: string | null
          availability_status?: RiderAvailability
          verification_status?: RiderVerificationStatus
          rating?: number
          total_deliveries?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          vehicle_type?: RiderVehicleType
          vehicle_number?: string
          driving_license_number?: string
          assigned_zone?: string | null
          availability_status?: RiderAvailability
          verification_status?: RiderVerificationStatus
          rating?: number
          total_deliveries?: number
          created_at?: string
          updated_at?: string
        }
      }
      categories: {
        Row: {
          id: string
          name: string
          slug: string
          description: string | null
          icon: string | null
          image_url: string | null
          parent_id: string | null
          is_active: boolean
          display_order: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          slug: string
          description?: string | null
          icon?: string | null
          image_url?: string | null
          parent_id?: string | null
          is_active?: boolean
          display_order?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          description?: string | null
          icon?: string | null
          image_url?: string | null
          parent_id?: string | null
          is_active?: boolean
          display_order?: number
          created_at?: string
          updated_at?: string
        }
      }
      products: {
        Row: {
          id: string
          shop_id: string
          category_id: string | null
          title: string
          slug: string
          description: string | null
          price: number
          original_price: number | null
          stock_quantity: number
          sku: string | null
          images: string[]
          status: ProductStatus
          is_featured: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          shop_id: string
          category_id?: string | null
          title: string
          slug: string
          description?: string | null
          price: number
          original_price?: number | null
          stock_quantity?: number
          sku?: string | null
          images?: string[]
          status?: ProductStatus
          is_featured?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          shop_id?: string
          category_id?: string | null
          title?: string
          slug?: string
          description?: string | null
          price?: number
          original_price?: number | null
          stock_quantity?: number
          sku?: string | null
          images?: string[]
          status?: ProductStatus
          is_featured?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      orders: {
        Row: {
          id: string
          order_number: string
          customer_id: string | null
          shop_id: string | null
          total_amount: number
          delivery_fee: number
          discount_amount: number
          payment_method: PaymentMethod
          payment_status: PaymentStatus
          order_status: OrderStatus
          shipping_address: Json
          customer_notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          order_number: string
          customer_id?: string | null
          shop_id?: string | null
          total_amount: number
          delivery_fee?: number
          discount_amount?: number
          payment_method?: PaymentMethod
          payment_status?: PaymentStatus
          order_status?: OrderStatus
          shipping_address: Json
          customer_notes?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          order_number?: string
          customer_id?: string | null
          shop_id?: string | null
          total_amount?: number
          delivery_fee?: number
          discount_amount?: number
          payment_method?: PaymentMethod
          payment_status?: PaymentStatus
          order_status?: OrderStatus
          shipping_address?: Json
          customer_notes?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string | null
          product_title: string
          unit_price: number
          quantity: number
          total_price: number
          created_at: string
        }
        Insert: {
          id?: string
          order_id: string
          product_id?: string | null
          product_title: string
          unit_price: number
          quantity?: number
          total_price: number
          created_at?: string
        }
        Update: {
          id?: string
          order_id?: string
          product_id?: string | null
          product_title?: string
          unit_price?: number
          quantity?: number
          total_price?: number
          created_at?: string
        }
      }
      deliveries: {
        Row: {
          id: string
          order_id: string
          rider_id: string | null
          pickup_address: string
          dropoff_address: string
          delivery_status: DeliveryStatus
          assigned_at: string | null
          picked_up_at: string | null
          delivered_at: string | null
          delivery_notes: string | null
          proof_of_delivery_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          order_id: string
          rider_id?: string | null
          pickup_address: string
          dropoff_address: string
          delivery_status?: DeliveryStatus
          assigned_at?: string | null
          picked_up_at?: string | null
          delivered_at?: string | null
          delivery_notes?: string | null
          proof_of_delivery_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          order_id?: string
          rider_id?: string | null
          pickup_address?: string
          dropoff_address?: string
          delivery_status?: DeliveryStatus
          assigned_at?: string | null
          picked_up_at?: string | null
          delivered_at?: string | null
          delivery_notes?: string | null
          proof_of_delivery_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      platform_settings: {
        Row: {
          id: string
          key: string
          value: Json
          description: string | null
          updated_at: string
        }
        Insert: {
          id?: string
          key: string
          value: Json
          description?: string | null
          updated_at?: string
        }
        Update: {
          id?: string
          key?: string
          value?: Json
          description?: string | null
          updated_at?: string
        }
      }
    }
  }
}
