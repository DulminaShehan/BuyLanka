-- BuyLanka Rider GPS Tracking & Delivery Workflow Migration
-- PostgreSQL / Supabase Migration 003

-- 1. Add current GPS coordinates and online flag to riders table
ALTER TABLE public.riders
ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS current_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS current_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_location_updated_at TIMESTAMPTZ;

-- 2. Expand delivery_status check constraint to support the full 8-step delivery workflow
ALTER TABLE public.deliveries DROP CONSTRAINT IF EXISTS deliveries_delivery_status_check;
ALTER TABLE public.deliveries ADD CONSTRAINT deliveries_delivery_status_check CHECK (
    delivery_status IN (
        'unassigned',
        'assigned',
        'accepted',
        'going_to_pickup',
        'arrived_at_pickup',
        'picked_up',
        'going_to_customer',
        'arrived_at_customer',
        'delivered',
        'failed',
        'cancelled'
    )
);

-- 3. Add pickup & dropoff coordinates if not present
ALTER TABLE public.deliveries
ADD COLUMN IF NOT EXISTS pickup_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS pickup_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS dropoff_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS dropoff_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS distance_km NUMERIC(6, 2),
ADD COLUMN IF NOT EXISTS estimated_minutes INTEGER;

-- 4. Create rider_locations table for live breadcrumbs & tracking
CREATE TABLE IF NOT EXISTS public.rider_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID NOT NULL REFERENCES public.riders(id) ON DELETE CASCADE,
    delivery_id UUID REFERENCES public.deliveries(id) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_rider_locations_rider ON public.rider_locations(rider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rider_locations_delivery ON public.rider_locations(delivery_id);

-- 5. Row Level Security (RLS) Policies
ALTER TABLE public.rider_locations ENABLE ROW LEVEL SECURITY;

-- Admins full access
CREATE POLICY "Admins have full access to rider locations"
    ON public.rider_locations FOR ALL
    USING (public.is_admin());

-- Riders can view and update their own rider record & availability
CREATE POLICY "Riders can update own availability and location"
    ON public.riders FOR UPDATE
    USING (auth.uid() = id);

-- Riders can insert their own GPS breadcrumbs
CREATE POLICY "Riders can insert own location"
    ON public.rider_locations FOR INSERT
    WITH CHECK (auth.uid() = rider_id);

CREATE POLICY "Riders can view own locations"
    ON public.rider_locations FOR SELECT
    USING (auth.uid() = rider_id);

-- Riders can update status of deliveries assigned to them
CREATE POLICY "Riders can update assigned deliveries"
    ON public.deliveries FOR UPDATE
    USING (auth.uid() = rider_id);

-- Riders can view orders for their assigned deliveries
CREATE POLICY "Riders can view assigned orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.deliveries 
            WHERE deliveries.order_id = orders.id AND deliveries.rider_id = auth.uid()
        )
    );

-- Riders can view order items for their assigned deliveries
CREATE POLICY "Riders can view assigned order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.deliveries 
            WHERE deliveries.order_id = order_items.order_id AND deliveries.rider_id = auth.uid()
        )
    );
