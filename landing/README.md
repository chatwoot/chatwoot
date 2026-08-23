# Whisker Landing 🐾

Static landing/docs site for [Whisker](https://github.com/maddixmhn/Whisker) — deployable to Vercel in under a minute. No build step.

## Deploy to Vercel

### Option A — CLI

```bash
cd landing
npx vercel --prod
```

### Option B — Dashboard (recommended)

1. Push the repo to GitHub.
2. [vercel.com/new](https://vercel.com/new) → import `maddixmhn/Whisker`.
3. Set **Root Directory** to `landing`.
4. Framework preset: **Other** (static). Deploy.

## Custom domain

1. Buy the domain at any registrar, e.g.:
   - **whisker.chat** ← best match
   - whisker.im · getwhisker.app · whiskerhq.dev
2. In Vercel: Project → Settings → Domains → add your domain.
3. Point the domain to Vercel (`cname.vercel-dns.com` or the A record Vercel shows). DNS/SSL is automatic.

> Note: this static site is the marketing/docs home (like chatwoot.com).
> The Whisker **app itself** (Rails + Postgres + Redis + Sidekiq) needs a VM/container host —
> see the repo's `docker-compose.production.yaml` for one-command self-hosting.
