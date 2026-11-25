# 24HOURS RADIO

Mobile-first radio station website and staff portal.

## Files
- `index.html` — public station website and online player.
- `admin.html` — Admin/DJ staff portal.
- `admin.js` — staff sign-in and content management.
- `supabase-config.js` — public Supabase URL/key placeholders only.
- `supabase/schema.sql` — database tables, role controls, and Row Level Security policies.

## Deploy to Vercel
Import this repository into Vercel. Select Framework Preset **Other**, leave Build Command empty, and set Output Directory to `.`.

## Supabase connection (blocked by free-project limit)
A separate Supabase project could not be created because the account has reached its two active free-project limit. This radio project has NOT been connected to another project's database. When a dedicated radio project is available:
1. Run `supabase/schema.sql` in its SQL Editor.
2. Put its Project URL and publishable/anon key in `supabase-config.js`.
3. Create the first account in Supabase Auth.
4. Promote the first Admin using the commented SQL at the bottom of `supabase/schema.sql` (replace the email).
5. Add DJ accounts in Supabase Auth, then use the Admin staff-role panel to assign the DJ role.
6. Save a real HTTPS radio stream URL from the Admin dashboard.

Only the publishable/anon key belongs in frontend code. Never expose a service-role key.

## Live radio and FM
The website player needs a real audio stream URL from an Icecast/SHOUTcast server or streaming provider. FM transmission also requires a licensed frequency and transmitter/studio equipment. Neither is automatically supplied by this repository.

## Current readiness
The website and Admin/DJ portal files are in GitHub and ready for Vercel deployment as a static site. Supabase login and shared content management remain inactive until the dedicated database is connected.
