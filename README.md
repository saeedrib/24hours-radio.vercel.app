# 24HOURS RADIO

Mobile-first radio station website and staff portal.

## Files
- `index.html` — public station website, online player, and live content feed.
- `admin.html` — Admin/DJ staff portal.
- `admin.js` — staff sign-in and content management.
- `supabase-config.js` — public Supabase URL and publishable key only.
- `supabase/schema.sql` — database tables, role controls, and Row Level Security policies.

## Supabase connection
The radio system is connected to the existing **Student Loan Found** Supabase project. Radio data is isolated in six new `radio_*` tables with Row Level Security enabled. Existing student-loan, NFPS, and Shafa tables were not modified.

The public website reads published programs, presenters, news, podcasts, and the live stream URL from these radio tables. Staff use `admin.html` to manage station content.

## First Admin setup
1. Create a staff account in Supabase Authentication (email/password).
2. Send the exact account email to the project owner/admin so that the account can be promoted to the first Radio Admin.
3. The first Radio Admin can then assign DJ roles from the staff portal.
4. Do not allow public visitors to choose an Admin or DJ role.

The frontend uses only the Supabase publishable key. Never expose a service-role or secret key.

## Deploy to Vercel
Import this repository into Vercel. Select Framework Preset **Other**, leave Build Command empty, and set Output Directory to `.`.

## Live radio and FM
The website player still needs a real HTTPS audio stream URL from an Icecast/SHOUTcast server or streaming provider. Save it from the Admin dashboard after the first Admin is enabled. FM transmission also requires a licensed frequency and transmitter/studio equipment. Neither is automatically supplied by this repository.
