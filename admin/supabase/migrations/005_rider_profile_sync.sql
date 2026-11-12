-- BuyLanka Rider Profile Updates Synchronization Migration
-- Migration: 005_rider_profile_sync.sql

-- 1. Add extra rider profile fields to public.riders
ALTER TABLE public.riders
ADD COLUMN IF NOT EXISTS residential_address TEXT,
ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
ADD COLUMN IF NOT EXISTS nic_number TEXT,
ADD COLUMN IF NOT EXISTS profile_update_status TEXT NOT NULL DEFAULT 'approved' 
    CHECK (profile_update_status IN ('approved', 'pending_review', 'rejected'));

-- 2. Create rider_profile_change_requests table for sensitive document / vehicle updates
CREATE TABLE IF NOT EXISTS public.rider_profile_change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID NOT NULL REFERENCES public.riders(id) ON DELETE CASCADE,
    change_type TEXT NOT NULL DEFAULT 'sensitive_details' 
        CHECK (change_type IN ('sensitive_details', 'vehicle_change', 'license_change', 'document_change', 'general')),
    requested_changes JSONB NOT NULL,
    previous_values JSONB NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    admin_remarks TEXT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_rider_profile_changes_rider ON public.rider_profile_change_requests(rider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rider_profile_changes_status ON public.rider_profile_change_requests(status);

-- 3. Row Level Security (RLS) Policies
ALTER TABLE public.rider_profile_change_requests ENABLE ROW LEVEL SECURITY;

-- Admins full access
CREATE POLICY "Admins full access to rider profile change requests"
    ON public.rider_profile_change_requests FOR ALL
    USING (public.is_admin());

-- Riders can view own change requests
CREATE POLICY "Riders can view own change requests"
    ON public.rider_profile_change_requests FOR SELECT
    USING (auth.uid() = rider_id);

-- Riders can submit their own change requests
CREATE POLICY "Riders can submit own change requests"
    ON public.rider_profile_change_requests FOR INSERT
    WITH CHECK (auth.uid() = rider_id);

-- 4. Enable Supabase Realtime for instant synchronization
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_profile_change_requests;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 5. Stored Procedure: Admin Approves Sensitive Profile Change Request
CREATE OR REPLACE FUNCTION public.approve_rider_profile_change_request(
    p_request_id UUID,
    p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_req RECORD;
    v_new_vehicle_number TEXT;
    v_new_license TEXT;
    v_new_vehicle_type TEXT;
    v_new_model TEXT;
    v_new_color TEXT;
BEGIN
    -- Fetch request
    SELECT * INTO v_req 
    FROM public.rider_profile_change_requests 
    WHERE id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Change request not found';
    END IF;

    IF v_req.status != 'pending' THEN
        RAISE EXCEPTION 'Change request is already %', v_req.status;
    END IF;

    -- Extract values from JSONB
    v_new_vehicle_number := v_req.requested_changes->>'vehicle_number';
    v_new_license := v_req.requested_changes->>'driving_license_number';
    v_new_vehicle_type := v_req.requested_changes->>'vehicle_type';
    v_new_model := v_req.requested_changes->>'vehicle_model';
    v_new_color := v_req.requested_changes->>'vehicle_color';

    -- Apply approved values to riders table
    UPDATE public.riders
    SET 
        vehicle_number = COALESCE(v_new_vehicle_number, vehicle_number),
        driving_license_number = COALESCE(v_new_license, driving_license_number),
        vehicle_type = COALESCE(v_new_vehicle_type, vehicle_type),
        vehicle_model = COALESCE(v_new_model, vehicle_model),
        vehicle_color = COALESCE(v_new_color, vehicle_color),
        profile_update_status = 'approved',
        updated_at = timezone('utc'::text, now())
    WHERE id = v_req.rider_id;

    -- Update change request status
    UPDATE public.rider_profile_change_requests
    SET 
        status = 'approved',
        reviewed_by = p_admin_id,
        reviewed_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_request_id;

    -- Notify rider
    INSERT INTO public.notifications (user_id, title, message, type, data)
    VALUES (
        v_req.rider_id,
        'Profile Changes Approved! 🎉',
        'Your submitted vehicle and verification details have been verified and approved by the BuyLanka Admin team.',
        'system',
        jsonb_build_object('request_id', p_request_id, 'status', 'approved')
    );

    RETURN jsonb_build_object('success', true, 'status', 'approved');
END;
$$;

-- 6. Stored Procedure: Admin Rejects Sensitive Profile Change Request
CREATE OR REPLACE FUNCTION public.reject_rider_profile_change_request(
    p_request_id UUID,
    p_admin_id UUID DEFAULT NULL,
    p_remarks TEXT DEFAULT 'Documents could not be verified'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_req RECORD;
BEGIN
    SELECT * INTO v_req 
    FROM public.rider_profile_change_requests 
    WHERE id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Change request not found';
    END IF;

    IF v_req.status != 'pending' THEN
        RAISE EXCEPTION 'Change request is already %', v_req.status;
    END IF;

    -- Update change request with rejection remarks
    UPDATE public.rider_profile_change_requests
    SET 
        status = 'rejected',
        admin_remarks = p_remarks,
        reviewed_by = p_admin_id,
        reviewed_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_request_id;

    -- Update rider status to rejected
    UPDATE public.riders
    SET 
        profile_update_status = 'rejected',
        updated_at = timezone('utc'::text, now())
    WHERE id = v_req.rider_id;

    -- Notify rider with admin's remarks
    INSERT INTO public.notifications (user_id, title, message, type, data)
    VALUES (
        v_req.rider_id,
        'Profile Update Rejected',
        COALESCE(p_remarks, 'Your vehicle/license update could not be approved. Please review your details and contact Admin support.'),
        'system',
        jsonb_build_object('request_id', p_request_id, 'status', 'rejected', 'remarks', p_remarks)
    );

    RETURN jsonb_build_object('success', true, 'status', 'rejected');
END;
$$;

