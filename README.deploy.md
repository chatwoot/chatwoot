# Chatwoot — Build, Push & Deploy (production)

This stack builds the Chatwoot image, pushes it to `ghcr.io/kira-id`, and runs
rails + sidekiq + postgres + redis using the prebuilt image. Secrets/connection
params come from the repo `.env` via `env_file`.

## Prerequisites (one-time)
- Docker + `docker buildx` installed and running.
- Authenticated to GitHub Container Registry:
  ```bash
  echo $GITHUB_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin
  ```
  Confirm with `docker pull ghcr.io/kira-id/chatwoot:latest` (a "not found" is fine).
- A populated `.env` file in this repo root.
- POSIX shell (Git Bash / bash).

## Fixes required before building
These are real fork bugs; the build/deploy fails without them.

### 1. nokogiri native compile (`docker/Dockerfile`)
On alpine 3.21 / Ruby 3.4.4 the vendored static libs don't emit, so the bundle
step fails linking `libxml2.a`/`libxslt.a`. Fix:
- In the `pre-builder` stage `apk add`, add `libxml2-dev libxslt-dev`.
- Add `ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1` before the bundle step.
- In the runtime stage `apk add`, add `libxml2 libxslt`.

### 2. Missing `postcss-import` dependency (`package.json`)
`postcss.config.js` does `require('postcss-import')` but it wasn't a declared dep
(pnpm strict isolation). Add to `devDependencies`:
```json
"postcss-import": "15.1.0"
```
then sync the lockfile:
```bash
pnpm install
```

### 3. Invalid JS in `theme/colors.js`
Color scales were written as `25: #f9f9f9,` (unquoted `#hex` = syntax error),
which broke Tailwind's config loader and `assets:precompile`. Quote all hex values:
```bash
cd ~/Documents/Kiraid/chatwoot   # or: cd to this repo root
perl -i -pe "s/:\s*#([0-9a-fA-F]{3,8})\b/: '#\$1'/g" theme/colors.js
```
Also fix the ESM imports in `tailwind.config.js` (lines ~2-3) to include the
`.js` extension:
```js
import { colors } from './theme/colors.js';
import { icons } from './theme/icons.js';
```

## Build & push the image (linux/amd64)
This is the longest build (bundle install + `assets:precompile`, ~10+ min). Run it
in the background and watch its own log file:
```bash
docker buildx build --platform linux/amd64 --tag ghcr.io/kira-id/chatwoot:latest --push -f docker/Dockerfile . > /tmp/build-chatwoot.log 2>&1
```
> Use a SEPARATE log file per build. Sharing one log filename across parallel
> builds makes their logs clobber each other.

Verify it landed:
```bash
docker buildx imagetools inspect ghcr.io/kira-id/chatwoot:latest | grep -m1 "Digest:"
```

## Deploy (production compose, uses the ghcr image)
```bash
docker compose -f docker-compose.production.yaml up -d
```
- Rails published at `127.0.0.1:3000` (→ container port 3000).
- Postgres (`pgvector/pgvector:pg16`) and Redis (`redis:alpine`) start automatically.

## Verify end-to-end
```bash
curl -s -o /dev/null -w "chatwoot HTTP %{http_code}\n" http://127.0.0.1:3000/api
```
Expect `HTTP 200`.

## Notes
- **First boot**: the `rails` container runs `db:prepare` (create/migrate DB). Allow
  ~1–2 minutes before `:3000/api` returns 200.
- **Redis auth**: the `.env` has an empty `REDIS_PASSWORD` and
  `REDIS_URL=redis://redis:6379` (no auth). The compose `redis` command only sets
  `requirepass` when `REDIS_PASSWORD` is non-empty, so leave it empty or set both
  consistently. Do NOT add `requirepass` blindly or Redis will reject connections.
- **Redeploy after a new push**: containers don't auto-update.
  ```bash
  docker compose -f docker-compose.production.yaml pull && docker compose -f docker-compose.production.yaml up -d
  ```
- Secrets used from `.env`: `POSTGRES_*`, `REDIS_URL`, `SECRET_KEY_BASE`, etc.
