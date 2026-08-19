-- BuyLanka Row Level Security (RLS) Policies
-- PostgreSQL / Supabase Migration

-- 1. Helper function to check if the current user is an Admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- 3. Profiles Policies
CREATE POLICY "Admins have full access to profiles"
    ON public.profiles FOR ALL
    USING (public.is_admin());

CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 4. Sellers Policies
CREATE POLICY "Admins have full access to sellers"
    ON public.sellers FOR ALL
    USING (public.is_admin());

CREATE POLICY "Sellers can view own record"
    ON public.sellers FOR SELECT
    USING (auth.uid() = id);

-- 5. Shops Policies
CREATE POLICY "Admins have full access to shops"
    ON public.shops FOR ALL
    USING (public.is_admin());

CREATE POLICY "Public can view approved shops"
    ON public.shops FOR SELECT
    USING (status = 'approved' OR public.is_admin());

CREATE POLICY "Sellers can manage own shop"
    ON public.shops FOR ALL
    USING (auth.uid() = seller_id);

-- 6. Riders Policies
CREATE POLICY "Admins have full access to riders"
    ON public.riders FOR ALL
    USING (public.is_admin());

CREATE POLICY "Riders can view own record"
    ON public.riders FOR SELECT
    USING (auth.uid() = id);

-- 7. Categories Policies
CREATE POLICY "Admins have full access to categories"
    ON public.categories FOR ALL
    USING (public.is_admin());

CREATE POLICY "Public can view active categories"
    ON public.categories FOR SELECT
    USING (is_active = true OR public.is_admin());

-- 8. Products Policies
CREATE POLICY "Admins have full access to products"
    ON public.products FOR ALL
    USING (public.is_admin());

CREATE POLICY "Public can view published products"
    ON public.products FOR SELECT
    USING (status = 'published' OR public.is_admin());

-- 9. Orders & Order Items Policies
CREATE POLICY "Admins have full access to orders"
    ON public.orders FOR ALL
    USING (public.is_admin());

CREATE POLICY "Customers can view their orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = customer_id);

CREATE POLICY "Admins have full access to order items"
    ON public.order_items FOR ALL
    USING (public.is_admin());

-- 10. Deliveries Policies
CREATE POLICY "Admins have full access to deliveries"
    ON public.deliveries FOR ALL
    USING (public.is_admin());

CREATE POLICY "Riders can view assigned deliveries"
    ON public.deliveries FOR SELECT
    USING (auth.uid() = rider_id);

-- 11. Platform Settings Policies
CREATE POLICY "Admins have full access to platform settings"
    ON public.platform_settings FOR ALL
    USING (public.is_admin());
