# Deploy

Everything runs on free plans: Supabase (data, auth, storage), Vercel Hobby (backend), GitHub Pages (web app), GitHub Releases (Android APK).

## 1. Supabase

1. In the Supabase dashboard of the project, open **SQL Editor**, paste [`supabase/migrations/20261001000000_init.sql`](../supabase/migrations/20261001000000_init.sql) and run it. It is safe to run twice.
2. **Authentication → Sign In / Providers**: turn on **Allow anonymous sign-ins** (participants join without an account). Email sign-in stays available.
3. **Storage**: the backend uses a private bucket named `event-media` (10 MB limit, JPEG and PNG). Create it if it does not exist yet.
4. Note the project URL, the publishable key and a secret key (**Project Settings → API Keys**).

Check the setup from your machine (creates and deletes one test event):

```bash
cd api
npm run check:supabase
```

## 2. Backend on Vercel

1. On vercel.com, **Add New → Project**, import the GitHub repository, set **Root Directory** to `api`. No build command is needed.
2. Environment variables (Production):

| Variable | Value |
| --- | --- |
| `DATA_MODE` | `supabase` |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` | from Supabase |
| `SUPABASE_BUCKET` | `event-media` |
| `YOUCAM_MODE` | `mock` to start; `live` when you want real renders |
| `YOUCAM_API_KEY`, `YOUCAM_API_BASE` | from the YouCam API console; base `https://yce-api-01.makeupar.com` |
| `LEDGER_CAP_PER_EVENT`, `LEDGER_CAP_PER_PARTICIPANT`, `LEDGER_ACCOUNT_RESERVE` | unit caps |
| `CORS_ORIGINS` | the web app origin, e.g. `https://<user>.github.io` |
| `GEMINI_API_KEY` | optional |

3. Deploy, then open `https://<project>.vercel.app/api/health`.

## 3. Web app on GitHub Pages

1. Repository **Settings → Secrets and variables → Actions → Variables**: add `API_BASE_URL` = `https://<project>.vercel.app`.
2. **Settings → Pages**: source **GitHub Actions**.
3. Push to `main` (or run the **Web app** workflow). The app is published at `https://<user>.github.io/<repo>/`.

## 4. Android APK

1. Add the repository variable `PUBLIC_WEB_URL` = `https://<user>.github.io/<repo>/` (used in invite links shared from the phone).
2. Tag a version: `git tag v0.1.0 && git push origin v0.1.0`. The **Android release** workflow builds the APK and attaches it to a GitHub Release.

## 5. Live renders

Keep `YOUCAM_MODE=mock` while testing the flow. Switch to `live` in Vercel when ready, with caps that fit the unit balance. Every paid call is checked against the caps and the live balance first.
