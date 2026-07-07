# Aps Pickle Zone User Guide

Version: 1.0

## 1. Overview

Aps Pickle Zone is a dynamic web app for pickleball court reservations and court operations. Customers can register, book courts, upload payment proof, track personal progress, receive notifications, and manage their profile. Admin users can approve bookings, manage courts, send customer notifications, track active rentals, review reports, and manage maintenance.

The app is designed as an installable web app. It can be opened in a browser and installed from supported browsers as a standalone app.

## 2. User Roles

### Customer

Customers can:

- Create an account and log in.
- Book available pickleball courts.
- Upload payment proof.
- Track booking status and receipts.
- View availability schedules.
- Receive booking and admin notifications.
- Track personal progress, court hours, streaks, and productivity.
- Update profile details and profile photo.
- View leaderboard rankings.

### Admin

Admins can:

- Review and approve or decline booking requests.
- Verify payment proof.
- Manage customer profiles.
- Send direct notifications to customers.
- View customer profile photos.
- Manage court availability and maintenance.
- Monitor active rentals with live countdowns.
- Review revenue reports and booking summaries.
- View activity logs.

## 3. Accessing the App

1. Open the web app URL provided by the owner or deployment host.
2. Use the navigation menu to go to Login or Register.
3. On mobile, open the side menu from the app bar.
4. On supported browsers, install the app from the browser install prompt or menu.

## 4. Customer Guide

### Register an Account

1. Open Register.
2. Enter full name, username, contact number, and password.
3. Select Create Account.
4. After registration, log in using the username and password.

Usernames must use lowercase letters, numbers, dots, dashes, or underscores.

### Log In

1. Open Login.
2. Enter username and password.
3. Select Login.

If login fails, confirm the account exists and that Supabase email confirmation is disabled or the account has been confirmed by the owner.

### Book a Court

1. Open Book.
2. Select a court.
3. Select the booking date.
4. Select the start time.
5. Select the number of hours.
6. Confirm the slot is available.
7. Select Submit Booking Request.

Booking rules:

- Court rate is PHP 250.00 per hour.
- Default maximum booking duration is 4 hours.
- Bookings can run up to 11:00 PM.
- Pending, approved, and active bookings block overlapping reservations.
- Maintenance blocks prevent booking affected courts.

### Upload Payment Proof

1. Open Bookings.
2. Select the booking.
3. In Payment Proof, select a JPG, PNG, or PDF file.
4. Select Upload Proof.
5. Wait for admin verification.

Payment proof files must be 8 MB or smaller.

### Track Bookings

Open Bookings to see:

- Booking reference.
- Court and date.
- Time range.
- Total amount.
- Payment status.
- Booking status.
- Receipt and print option when billable.

Statuses include Pending, Approved, Active, Completed, Cancelled, and Declined.

### View Court Availability

Open Schedule to view court availability by date. Green slots are open. Busy, maintenance, or closed slots cannot be booked.

### Notifications

Open Notifications to see:

- Booking updates.
- Time reminders.
- Admin messages.

Admin messages display as full message cards so the content is easy to read. Use Mark All Read or the check button to clear unread indicators.

### Personal Progress

Open Progress to track:

- Productivity score.
- Monthly court goal.
- Weekly and monthly hours.
- Active days.
- Current and best streaks.
- Completed sessions.
- Verified spend.
- Favorite court.

The Dashboard also shows a quick progress summary and recent notifications.

### Update Profile

1. Open Profile.
2. Edit full name or contact number.
3. Select Change Profile Photo to choose a JPG or PNG image.
4. Select Save Profile.

Profile photos must be 15 MB or smaller. The image preview updates immediately after selection and after saving.

## 5. Admin Guide

### Admin Dashboard

The Admin Dashboard shows:

- Total customers.
- Pending booking requests.
- Approved bookings today.
- Active renters.
- Available courts.
- Total income.
- Recent booking requests.
- Active rental countdowns.
- Player of the Week.

### Review Bookings

1. Open Bookings.
2. Search or filter by status, court, or date range.
3. Select a booking to view details.
4. Review payment proof if uploaded.
5. Select Approve, Decline, Cancel, or Complete when appropriate.

Admin notes are shown to the customer on the booking details page.

### Customer Management

Open Customers to:

- Search customer profiles.
- View customer profile photos.
- View booking count, rental hours, and verified payments.
- Review recent bookings.
- Send direct notifications.

### Send Customer Notifications

1. Open Customers.
2. Select Notify on the customer card.
3. Enter a title and message.
4. Select Send.

The message appears in the customer's Notifications page as a full admin message card.

### Court Management

Open Courts to:

- Set a court as Available.
- Mark a court for Maintenance.
- Mark a court as Inactive.
- Add maintenance or status notes.

### Active Rentals

Open Active to see live countdown timers for rentals currently in progress. Timers update smoothly without requiring manual refresh.

### Reports

Open Reports to review:

- Daily income.
- Weekly income.
- Monthly income.
- Most rented court.
- Top renters.
- Booking status summary.

### Maintenance Scheduling

Open Maintenance to block court time for maintenance or private events. Maintenance blocks prevent new bookings in the affected time range.

### Activity Logs

Open Logs to review important admin actions.

## 6. Real-Time Behavior

The app uses Supabase Realtime for key data updates. Booking changes, notifications, court updates, maintenance changes, profile changes, and admin activity updates refresh quietly in the background.

The app also reduces unnecessary full-screen refreshes. Countdown timers update locally, while data changes are debounced to avoid repeated reloads.

## 7. Setup Notes for Owners

### Supabase Setup

Run the main schema in Supabase SQL Editor:

```sql
supabase/schema.sql
```

For existing installations, also run:

```sql
supabase/username_only_profiles_patch.sql
supabase/profile_image_bucket_limit_patch.sql
```

The profile image patch raises the private profile image bucket limit to 15 MB.

### Environment Variables

Set these values in the deployment host:

- SUPABASE_URL
- SUPABASE_ANON_KEY

For local IDE testing, these can also be set in:

```text
assets/config/supabase.json
```

### Build the Web App

Use:

```powershell
C:\flutter\bin\flutter.bat build web --release
```

Deploy the generated folder:

```text
build/web
```

Supported hosts include Vercel, Netlify, Firebase Hosting, and other static hosts.

## 8. Troubleshooting

### Profile Photo Does Not Upload

Confirm the file is JPG or PNG and 15 MB or smaller. For existing Supabase projects, run `supabase/profile_image_bucket_limit_patch.sql`.

### Booking Slot Is Not Available

Check if the court is already pending, approved, active, under maintenance, inactive, or outside allowed booking hours.

### Customer Does Not See Admin Message

Confirm the admin selected the correct customer and that the customer opens the Notifications page. The app refreshes notifications in real time, but the customer can also use Refresh if the connection was interrupted.

### Payment Proof Cannot Upload

Use JPG, PNG, or PDF only. The file must be 8 MB or smaller.

### First User Is Not Admin

Promote a user in Supabase SQL Editor:

```sql
update public.profiles
set role = 'admin'
where username = 'your_admin_username';
```

## 9. Recommended Client Handover Checklist

- Confirm Supabase URL and anon key are configured.
- Register one admin account.
- Register one test customer account.
- Create and approve a test booking.
- Upload payment proof.
- Upload a customer profile photo.
- Send an admin message to the customer.
- Confirm realtime notification display.
- Confirm web app installation from browser.
- Confirm reports and active timers work.

