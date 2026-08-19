-- BuyLanka Seed Data & Setup Helpers
-- PostgreSQL / Supabase

-- 1. Default Categories for Sri Lankan Marketplace
INSERT INTO public.categories (name, slug, description, icon, is_active, display_order)
VALUES
    ('Ceylon Spices & Tea', 'ceylon-spices-tea', 'Authentic Ceylon Cinnamon, Black Tea, Cardamom & Spices', 'Coffee', true, 1),
    ('Handicrafts & Batik', 'handicrafts-batik', 'Traditional Sri Lankan masks, brassware, wooden crafts & batik clothing', 'Palette', true, 2),
    ('Ayurvedic & Wellness', 'ayurvedic-wellness', 'Natural herbal remedies, balms, oils & organic cosmetics', 'HeartPulse', true, 3),
    ('Electronics & Gadgets', 'electronics-gadgets', 'Smartphones, home appliances, computers & accessories', 'Smartphone', true, 4),
    ('Fashion & Apparel', 'fashion-apparel', 'Men, women and kids clothing, saris, and footwear', 'Shirt', true, 5),
    ('Fresh Produce & Coconut', 'fresh-produce-coconut', 'Farm fresh vegetables, tropical fruits, coconut products', 'Apple', true, 6),
    ('Jewellery & Gems', 'jewellery-gems', 'Ceylon blue sapphires, moonstones and handcrafted jewellery', 'Gem', true, 7),
    ('Home & Kitchenware', 'home-kitchenware', 'Clay pots, cookware, furniture and home decor', 'Home', true, 8)
ON CONFLICT (slug) DO NOTHING;

-- 2. Platform Default Settings
INSERT INTO public.platform_settings (key, value, description)
VALUES
    ('marketplace_info', '{"name": "BuyLanka", "currency": "LKR", "country": "Sri Lanka", "contact_email": "support@buylanka.lk", "support_phone": "+94 11 234 5678"}'::jsonb, 'General marketplace settings'),
    ('commission_config', '{"default_commission_rate": 10.0, "min_payout_amount": 5000, "payout_frequency": "weekly"}'::jsonb, 'Commission and seller payout parameters'),
    ('delivery_config', '{"base_delivery_fee": 350.0, "per_km_fee": 50.0, "free_delivery_threshold": 10000.0}'::jsonb, 'Delivery calculation settings in LKR')
ON CONFLICT (key) DO NOTHING;

-- Note for Admin User Creation:
-- When an admin signs up via Supabase Auth or email/password, ensure their profile role is set to 'admin':
-- UPDATE public.profiles SET role = 'admin', status = 'active' WHERE email = 'your-admin-email@buylanka.lk';
