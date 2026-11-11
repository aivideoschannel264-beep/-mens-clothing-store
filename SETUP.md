# Setup (about 10 minutes, works from a phone)

1. **Supabase project:** supabase.com > New project (free plan is fine).
2. **Database:** SQL Editor > New query > paste all of `schema.sql` > Run.
3. **Admin user:** Authentication > Users > Add user > enter your email and a strong password (tick Auto Confirm). Then in SQL Editor run the last line of `schema.sql` (the commented `insert into public.admins ...`) with your email.
4. **Lock signups:** Authentication > Sign In / Providers > turn OFF "Allow new users to sign up".
5. **Connect the site:** Project Settings > API. Copy the Project URL and the `anon public` key into the top of `index.html` (`SB_URL`, `SB_KEY`). Never use the `service_role` key. Also change `WA` to your WhatsApp number.
6. **Host it:** upload the folder to Netlify (app.netlify.com/drop), Cloudflare Pages or Vercel. You get a public link.
7. **First use:** open `your-link/#admin`, log in, Products tab > "Import 6 sample products" (or add your own with photos). Place a test order from the shop, then open Orders and change its status.

Security: customers can only browse products and call `place_order`; order prices are calculated on the server. Only the admin account can edit products, upload photos, or read orders.
