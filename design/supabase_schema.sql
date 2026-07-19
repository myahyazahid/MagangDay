-- Supabase database schema for MagangDay

-- 1. Create profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    full_name TEXT,
    nim TEXT,
    university TEXT,
    study_program TEXT,
    semester INTEGER,
    profile_photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create internships table
CREATE TABLE public.internships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    position TEXT NOT NULL,
    mentor_name TEXT,
    mentor_email TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create activity_logs table
CREATE TABLE public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    internship_id UUID NOT NULL REFERENCES public.internships(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    title TEXT NOT NULL,
    project_name TEXT,
    category TEXT,
    description TEXT,
    start_time TIME,
    end_time TIME,
    duration_minutes INTEGER,
    technologies TEXT[],
    status TEXT DEFAULT 'Completed',
    challenges TEXT,
    learning TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.internships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Profiles
CREATE POLICY "Allow users to read their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Allow users to insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 6. RLS Policies for Internships
CREATE POLICY "Allow users to read their own internships" ON public.internships
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Allow users to insert their own internships" ON public.internships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own internships" ON public.internships
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own internships" ON public.internships
    FOR DELETE USING (auth.uid() = user_id);

-- 7. RLS Policies for Activity Logs
CREATE POLICY "Allow users to read their own activity logs" ON public.activity_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Allow users to insert their own activity logs" ON public.activity_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own activity logs" ON public.activity_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own activity logs" ON public.activity_logs
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Automatic updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Attach triggers to tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();

CREATE TRIGGER update_internships_updated_at BEFORE UPDATE ON public.internships
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();

CREATE TRIGGER update_activity_logs_updated_at BEFORE UPDATE ON public.activity_logs
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();
