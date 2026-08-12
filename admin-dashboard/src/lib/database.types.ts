export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  __InternalSupabase: { PostgrestVersion: '14.15' }
  public: {
    Tables: {
      addresses: {
        Row: {
          address_text: string | null
          building: string | null
          created_at: string
          id: string
          is_default: boolean
          label: string | null
          lat: number
          lng: number
          notes: string | null
          user_id: string
        }
        Insert: {
          address_text?: string | null
          building?: string | null
          created_at?: string
          id?: string
          is_default?: boolean
          label?: string | null
          lat: number
          lng: number
          notes?: string | null
          user_id: string
        }
        Update: {
          address_text?: string | null
          building?: string | null
          created_at?: string
          id?: string
          is_default?: boolean
          label?: string | null
          lat?: number
          lng?: number
          notes?: string | null
          user_id?: string
        }
        Relationships: []
      }
      banners: {
        Row: {
          action_type: Database['public']['Enums']['banner_action']
          action_value: string | null
          country_id: string | null
          created_at: string
          id: string
          image_url: string
          is_active: boolean
          sort_order: number
        }
        Insert: {
          action_type?: Database['public']['Enums']['banner_action']
          action_value?: string | null
          country_id?: string | null
          created_at?: string
          id?: string
          image_url: string
          is_active?: boolean
          sort_order?: number
        }
        Update: {
          action_type?: Database['public']['Enums']['banner_action']
          action_value?: string | null
          country_id?: string | null
          created_at?: string
          id?: string
          image_url?: string
          is_active?: boolean
          sort_order?: number
        }
        Relationships: []
      }
      branch_products: {
        Row: {
          branch_id: string
          id: string
          is_available: boolean
          price_override: number | null
          product_id: string
        }
        Insert: {
          branch_id: string
          id?: string
          is_available?: boolean
          price_override?: number | null
          product_id: string
        }
        Update: {
          branch_id?: string
          id?: string
          is_available?: boolean
          price_override?: number | null
          product_id?: string
        }
        Relationships: []
      }
      branches: {
        Row: {
          close_time: string
          country_id: string
          created_at: string
          delivery_fee: number
          delivery_radius_km: number
          id: string
          image_url: string | null
          is_active: boolean
          is_busy: boolean
          lat: number
          lng: number
          min_order: number
          name_ar: string
          name_en: string
          open_time: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          close_time?: string
          country_id: string
          created_at?: string
          delivery_fee?: number
          delivery_radius_km?: number
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_busy?: boolean
          lat: number
          lng: number
          min_order?: number
          name_ar: string
          name_en: string
          open_time?: string
          phone?: string | null
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['branches']['Insert']>
        Relationships: []
      }
      categories: {
        Row: {
          created_at: string
          id: string
          image_url: string | null
          is_active: boolean
          name_ar: string
          name_en: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          id?: string
          image_url?: string | null
          is_active?: boolean
          name_ar: string
          name_en: string
          sort_order?: number
        }
        Update: Partial<Database['public']['Tables']['categories']['Insert']>
        Relationships: []
      }
      countries: {
        Row: {
          created_at: string
          currency: string
          id: string
          is_active: boolean
          name: string
          phone_code: string
          tax_rate: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          currency: string
          id?: string
          is_active?: boolean
          name: string
          phone_code: string
          tax_rate?: number
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['countries']['Insert']>
        Relationships: []
      }
      drivers: {
        Row: {
          branch_id: string | null
          created_at: string
          current_lat: number | null
          current_lng: number | null
          id: string
          is_active: boolean
          is_online: boolean
          plate_number: string | null
          rating: number
          updated_at: string
          user_id: string
          vehicle_type: string | null
        }
        Insert: {
          branch_id?: string | null
          id?: string
          is_active?: boolean
          is_online?: boolean
          plate_number?: string | null
          rating?: number
          user_id: string
          vehicle_type?: string | null
        }
        Update: Partial<Database['public']['Tables']['drivers']['Insert']>
        Relationships: []
      }
      inventory_items: {
        Row: {
          branch_id: string
          id: string
          min_threshold: number
          name: string
          quantity: number
          unit: string | null
          updated_at: string
        }
        Insert: {
          branch_id: string
          id?: string
          min_threshold?: number
          name: string
          quantity?: number
          unit?: string | null
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['inventory_items']['Insert']>
        Relationships: []
      }
      notifications: {
        Row: {
          body_ar: string | null
          body_en: string | null
          created_at: string
          id: string
          is_read: boolean
          title_ar: string | null
          title_en: string | null
          user_id: string
        }
        Insert: {
          body_ar?: string | null
          body_en?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          title_ar?: string | null
          title_en?: string | null
          user_id: string
        }
        Update: Partial<Database['public']['Tables']['notifications']['Insert']>
        Relationships: []
      }
      order_items: {
        Row: {
          addons_json: Json
          id: string
          notes: string | null
          order_id: string
          product_id: string
          quantity: number
          size_id: string | null
          unit_price: number
        }
        Insert: {
          addons_json?: Json
          id?: string
          notes?: string | null
          order_id: string
          product_id: string
          quantity?: number
          size_id?: string | null
          unit_price: number
        }
        Update: Partial<Database['public']['Tables']['order_items']['Insert']>
        Relationships: []
      }
      order_status_history: {
        Row: {
          changed_by: string | null
          created_at: string
          id: string
          order_id: string
          status: Database['public']['Enums']['order_status']
        }
        Insert: {
          changed_by?: string | null
          created_at?: string
          id?: string
          order_id: string
          status: Database['public']['Enums']['order_status']
        }
        Update: Partial<Database['public']['Tables']['order_status_history']['Insert']>
        Relationships: []
      }
      orders: {
        Row: {
          address_id: string | null
          branch_id: string
          created_at: string
          delivered_at: string | null
          delivery_fee: number
          discount: number
          driver_id: string | null
          id: string
          notes: string | null
          order_type: Database['public']['Enums']['order_type']
          payment_method: Database['public']['Enums']['payment_method']
          payment_status: Database['public']['Enums']['payment_status']
          scheduled_at: string | null
          status: Database['public']['Enums']['order_status']
          subtotal: number
          tax: number
          total: number
          updated_at: string
          user_id: string
        }
        Insert: {
          address_id?: string | null
          branch_id: string
          created_at?: string
          delivered_at?: string | null
          delivery_fee?: number
          discount?: number
          driver_id?: string | null
          id?: string
          notes?: string | null
          order_type?: Database['public']['Enums']['order_type']
          payment_method?: Database['public']['Enums']['payment_method']
          payment_status?: Database['public']['Enums']['payment_status']
          scheduled_at?: string | null
          status?: Database['public']['Enums']['order_status']
          subtotal?: number
          tax?: number
          total?: number
          updated_at?: string
          user_id: string
        }
        Update: Partial<Database['public']['Tables']['orders']['Insert']>
        Relationships: []
      }
      product_addons: {
        Row: {
          id: string
          name_ar: string
          name_en: string
          price: number
          product_id: string
        }
        Insert: {
          id?: string
          name_ar: string
          name_en: string
          price?: number
          product_id: string
        }
        Update: Partial<Database['public']['Tables']['product_addons']['Insert']>
        Relationships: []
      }
      product_sizes: {
        Row: {
          id: string
          price_modifier: number
          product_id: string
          size_name: string
        }
        Insert: {
          id?: string
          price_modifier?: number
          product_id: string
          size_name: string
        }
        Update: Partial<Database['public']['Tables']['product_sizes']['Insert']>
        Relationships: []
      }
      products: {
        Row: {
          base_price: number
          calories: number | null
          category_id: string
          created_at: string
          description_ar: string | null
          description_en: string | null
          id: string
          image_url: string | null
          is_active: boolean
          name_ar: string
          name_en: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          base_price: number
          calories?: number | null
          category_id: string
          created_at?: string
          description_ar?: string | null
          description_en?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          name_ar: string
          name_en: string
          sort_order?: number
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['products']['Insert']>
        Relationships: []
      }
      promo_codes: {
        Row: {
          branch_ids: string[] | null
          code: string
          created_at: string
          id: string
          is_active: boolean
          max_discount: number | null
          min_order: number
          type: Database['public']['Enums']['promo_type']
          updated_at: string
          usage_limit: number | null
          used_count: number
          valid_from: string | null
          valid_to: string | null
          value: number
        }
        Insert: {
          branch_ids?: string[] | null
          code: string
          id?: string
          is_active?: boolean
          max_discount?: number | null
          min_order?: number
          type: Database['public']['Enums']['promo_type']
          usage_limit?: number | null
          used_count?: number
          valid_from?: string | null
          valid_to?: string | null
          value?: number
        }
        Update: Partial<Database['public']['Tables']['promo_codes']['Insert']>
        Relationships: []
      }
      promo_usage: {
        Row: {
          id: string
          order_id: string | null
          promo_id: string
          used_at: string
          user_id: string
        }
        Insert: {
          id?: string
          order_id?: string | null
          promo_id: string
          used_at?: string
          user_id: string
        }
        Update: Partial<Database['public']['Tables']['promo_usage']['Insert']>
        Relationships: []
      }
      reviews: {
        Row: {
          comment: string | null
          created_at: string
          id: string
          order_id: string
          rating: number
          user_id: string
        }
        Insert: {
          comment?: string | null
          created_at?: string
          id?: string
          order_id: string
          rating: number
          user_id: string
        }
        Update: Partial<Database['public']['Tables']['reviews']['Insert']>
        Relationships: []
      }
      users: {
        Row: {
          country_id: string | null
          created_at: string
          email: string | null
          id: string
          is_blocked: boolean
          language: Database['public']['Enums']['app_language']
          name: string | null
          phone: string | null
          points_balance: number
          role: Database['public']['Enums']['user_role']
          scope_branch_id: string | null
          scope_country_id: string | null
          updated_at: string
          wallet_balance: number
        }
        Insert: {
          country_id?: string | null
          email?: string | null
          id: string
          is_blocked?: boolean
          language?: Database['public']['Enums']['app_language']
          name?: string | null
          phone?: string | null
          points_balance?: number
          role?: Database['public']['Enums']['user_role']
          scope_branch_id?: string | null
          scope_country_id?: string | null
          wallet_balance?: number
        }
        Update: Partial<Database['public']['Tables']['users']['Insert']>
        Relationships: []
      }
    }
    Views: { [_ in never]: never }
    Functions: {
      is_staff: { Args: Record<string, never>; Returns: boolean }
      is_super_admin: { Args: Record<string, never>; Returns: boolean }
      my_role: { Args: Record<string, never>; Returns: Database['public']['Enums']['user_role'] }
    }
    Enums: {
      app_language: 'ar' | 'en'
      banner_action: 'none' | 'product' | 'category' | 'url'
      order_status:
        | 'pending'
        | 'confirmed'
        | 'preparing'
        | 'ready'
        | 'on_the_way'
        | 'delivered'
        | 'cancelled'
      order_type: 'delivery' | 'pickup'
      payment_method: 'cash' | 'zaincash' | 'asiahawala' | 'fastpay' | 'qicard' | 'card' | 'wallet'
      payment_status: 'pending' | 'paid' | 'failed' | 'refunded'
      promo_type: 'percentage' | 'fixed' | 'free_delivery'
      user_role: 'customer' | 'driver' | 'cashier' | 'branch_manager' | 'country_manager' | 'super_admin'
    }
    CompositeTypes: { [_ in never]: never }
  }
}

type PublicSchema = Database['public']

export type Tables<T extends keyof PublicSchema['Tables']> =
  PublicSchema['Tables'][T]['Row']
export type TablesInsert<T extends keyof PublicSchema['Tables']> =
  PublicSchema['Tables'][T]['Insert']
export type TablesUpdate<T extends keyof PublicSchema['Tables']> =
  PublicSchema['Tables'][T]['Update']
export type Enums<T extends keyof PublicSchema['Enums']> = PublicSchema['Enums'][T]
