# Vidyasagar University SAR Web App v9 — GitHub Pages + Supabase

This version converts the browser-only document upload workflow into an online architecture:

- GitHub Pages hosts the static SAR web app.
- Supabase Auth handles sign-in.
- Supabase Postgres stores the five SAR cycles and current-cycle API values.
- Supabase Storage stores Category I, II and III supporting documents.
- Authenticated users can access the institution-wide SAR records and supporting documents under the supplied SQL policies.
- The existing five-cycle summary, current-cycle summary/declaration, Category I/II/III document upload controls, and local backup remain in the app.

## 1. Create Supabase project

Create a Supabase project at https://supabase.com/ . Then open **SQL Editor** and run `supabase_schema.sql` from this package.

The SQL creates:

- `sar_cycles`
- `sar_documents`
- `sar-documents` private Storage bucket
- RLS policies for authenticated users

The included policies intentionally allow signed-in users to read the institution-wide SAR records and documents. Upload/update/delete operations are tied to the authenticated user's identity where appropriate.

## 2. Configure the web app

In Supabase, open the project's API settings and copy the project URL and browser-safe publishable/anon key. Do **not** use or publish the `service_role` key.

The app supports two configuration methods:

### Simple method
Open `index.html` and replace:

```js
const SUPABASE_URL = window.VU_SUPABASE_URL || "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = window.VU_SUPABASE_ANON_KEY || "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY";
```

with your actual project URL and publishable/anon key.

### Cleaner method
Before `index.html` loads, define `window.VU_SUPABASE_URL` and `window.VU_SUPABASE_ANON_KEY` in a small configuration script. Do not commit secrets. The publishable/anon key is designed for browser use when RLS is correctly configured; the service role key must remain server-side.

## 3. GitHub Pages

Put `index.html` and `supabase_schema.sql` in your repository. For the live site, only `index.html` is required by the browser. The SQL file is a setup reference and does not need to be publicly exposed.

Recommended repository layout:

```text
vidyasagar-sar/
  index.html
  README.md
  supabase_schema.sql
```

Then in GitHub:

1. Create/open the repository.
2. Upload the files.
3. Commit changes.
4. Go to **Settings → Pages**.
5. Under **Build and deployment**, choose **Deploy from a branch**.
6. Select `main` and `/ (root)`.
7. Save.
8. Wait for GitHub Pages to publish the site.

## 4. First login

Open the published web app and use **Create account** with an institutional email. If Supabase email confirmation is enabled, confirm the email before signing in.

After signing in:

1. Select a SAR cycle.
2. Enter/edit the SAR data.
3. Upload supporting documents in Category I, II or III.
4. Click **Save current cycle to cloud**.
5. On another computer, sign in with an authorized account and click **Load all 5 cycles** or **Load current cycle from cloud**.
6. Use **Open saved file** to download a stored supporting document.

## 5. Important security rule

Never put the Supabase `service_role` key into `index.html`, GitHub, GitHub Pages, or any browser-visible JavaScript. Only use the browser-safe publishable/anon key with RLS policies enabled.

## 6. Current architecture

```text
GitHub Pages
   │
   └── index.html + Supabase JS client
             │
             ├── Supabase Auth
             ├── Postgres: sar_cycles
             ├── Postgres: sar_documents
             └── Storage: sar-documents
```

## 7. Optional next production step

For a university-wide deployment, consider adding an administrator role and making ordinary users edit only their own records while administrators can review all users' SAR submissions. The current SQL is intentionally institution-wide for authenticated read access because the requested workflow is to make uploaded documents available across authorized users.
