# Aps Pickle Zone

Aps Pickle Zone is a Flutter Pickleball Court Rental Management System backed by Supabase Auth, PostgreSQL, Storage, Row Level Security, and Realtime updates.

## Features

- Public landing, about, rates, login, and registration pages
- Customer dashboard, personal progress and productivity tracking, court booking, availability schedule, booking history, payment-proof upload, notifications, leaderboard, and profile editing
- Admin dashboard, booking verification, customer management, court status controls, active rental monitor, reports, maintenance scheduling, leaderboard, and activity logs
- Exactly 3 seeded courts: Court 1, Court 2, and Court 3
- Court rate: PHP 250.00 per court per hour
- Asia/Manila booking calculations and live rental countdowns
- Private Supabase Storage buckets for payment proofs and profile images
- SQL validation to prevent overlapping pending, approved, or active bookings

## Supabase Setup

1. Use the Supabase project/database named `apspickleball`, or create it if it does not exist yet.
2. In **Authentication > Providers > Email**, keep email/password auth enabled and turn off **Confirm email** for username-only login. The app stores username in `public.profiles`; Supabase Auth keeps a generated internal auth email only in `auth.users` because its password endpoint requires an email identifier.
3. Open the Supabase SQL Editor and run [`supabase/schema.sql`](supabase/schema.sql).
4. The first registered user becomes the initial admin automatically. All later users are customers.
5. Create your admin account from the app registration page after applying the schema. If it is the first registered account, it becomes admin automatically. If another account was created first, promote your account with:

```sql
update public.profiles
set role = 'admin'
where username = 'your_admin_username';
```

The schema creates tables, validation triggers, RLS policies, storage buckets, storage policies, helper RPC functions, seeded courts, and the configurable `max_rental_hours` setting.

For an existing database, run [`supabase/username_only_profiles_patch.sql`](supabase/username_only_profiles_patch.sql) once to add/backfill usernames and remove `public.profiles.email` without dropping booking data.

If profile photos larger than 5 MB fail, run [`supabase/profile_image_bucket_limit_patch.sql`](supabase/profile_image_bucket_limit_patch.sql) once to raise the `profile-images` storage bucket limit to 15 MB.

If login says the account needs confirmation, use one of these setup fixes in Supabase:

- Open **Authentication > Providers > Email** and turn off **Confirm email**.
- Or manually confirm a test account in the SQL Editor. Replace `your_username` with the username used in the app:

```sql
update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, now()),
    updated_at = now()
where email = 'apspicklezone+your_username@gmail.com';
```

## Environment

Copy [`.env.example`](.env.example) values into your deployment environment. For local Flutter runs, pass them as dart defines:

```powershell
C:\flutter\bin\flutter.bat run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
```

For quick local runs from an IDE, you can also edit [`assets/config/supabase.json`](assets/config/supabase.json):

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY"
}
```

The database name `apspickleball` is not the Supabase URL. In Supabase, copy the **Project URL** and **anon public key** from **Project Settings > API**.

For Vercel, add these environment variables for Production, Preview, and Development:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Local Development

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

## Installable Dynamic Web App

Build the dynamic installable web app as a PWA:

```powershell
C:\flutter\bin\flutter.bat build web --release
```

Deploy the generated `build/web` folder to Vercel, Netlify, Firebase Hosting, or any static host. The web app stays dynamic through Supabase Auth, PostgreSQL, Storage, and Realtime updates, and it includes a web manifest, mobile viewport metadata, app icons, and standalone display mode so users can install it from supported browsers.

```powershell
C:\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Use the local web-server command when you want a live development preview.

## Business Rules

- Customers can reserve one court for one or more hours when the slot is available.
- Default maximum rental duration is 4 hours. Change it in `public.app_settings`.
- A booking stays pending until an admin verifies the uploaded payment proof.
- Pending, approved, and active bookings block overlapping reservations for the same court and time.
- Maintenance blocks prevent new bookings in the affected time range.
- Admin actions are recorded in `admin_activity_logs`.

## Verification Checklist

- Register the first account and confirm it opens the admin dashboard.
- Register a customer account and create a booking request.
- Upload a JPG, PNG, or PDF payment proof from the booking details page.
- Approve or decline the booking from admin booking management.
- Confirm the customer receives notifications after approval or decline.
- Test availability blocking by trying the same court and time again.
- Let an approved booking reach its start time and confirm the active countdown appears.
- Check Player of the Week after marking rentals completed.
- Review daily, weekly, and monthly revenue on the reports page.
- Resize the app to mobile width and verify drawer navigation and forms remain usable.
