-- BuyLanka Customer Application Migration
-- PostgreSQL / Supabase Migration 004

-- 1. Customer Delivery Addresses Table
CREATE TABLE IF NOT EXISTS public.customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT 'Home', -- 'Home', 'Work', 'Other'
    recipient_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    delivery_instructions TEXT,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer ON public.customer_addresses(customer_id);

-- 2. Customer Favorites / Wishlist Table
CREATE TABLE IF NOT EXISTS public.customer_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT check_favorite_target CHECK (
        (shop_id IS NOT NULL AND product_id IS NULL) OR 
        (shop_id IS NULL AND product_id IS NOT NULL)
    ),
    CONSTRAINT unique_customer_shop_fav UNIQUE (customer_id, shop_id),
    CONSTRAINT unique_customer_prod_fav UNIQUE (customer_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_customer_favorites_customer ON public.customer_favorites(customer_id);

-- 3. Reviews & Ratings Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    shop_id UUID REFERENCES public.shops(id) ON DELETE SET NULL,
    rider_id UUID REFERENCES public.riders(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_order_review UNIQUE (order_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_shop ON public.reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rider ON public.reviews(rider_id);

-- 4. Customer Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'order', -- 'order', 'promo', 'system'
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read, created_at DESC);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Addresses: Customers manage own addresses
CREATE POLICY "Customers can manage own addresses"
    ON public.customer_addresses FOR ALL
    USING (auth.uid() = customer_id);

-- Favorites: Customers manage own favorites
CREATE POLICY "Customers can manage own favorites"
    ON public.customer_favorites FOR ALL
    USING (auth.uid() = customer_id);

-- Reviews: Customers can create reviews for completed orders they placed
CREATE POLICY "Customers can insert reviews"
    ON public.reviews FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Public can read reviews"
    ON public.reviews FOR SELECT
    USING (true);

-- Notifications: Users manage own notifications
CREATE POLICY "Users can manage own notifications"
    ON public.notifications FOR ALL
    USING (auth.uid() = user_id);

-- Orders: Customers can create orders for themselves and view own orders
CREATE POLICY "Customers can insert orders"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can view own orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = customer_id);

-- Order items: Customers can insert and view items for own orders
CREATE POLICY "Customers can insert order items"
    ON public.order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id AND orders.customer_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view own order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id AND orders.customer_id = auth.uid()
        )
    );

-- Deliveries & Rider Locations: Customers can view delivery tracking & live rider coordinates for active orders
CREATE POLICY "Customers can view assigned delivery"
    ON public.deliveries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = deliveries.order_id AND orders.customer_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view active rider location"
    ON public.rider_locations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.deliveries
            JOIN public.orders ON orders.id = deliveries.order_id
            WHERE deliveries.id = rider_locations.delivery_id 
              AND orders.customer_id = auth.uid()
        )
    );
