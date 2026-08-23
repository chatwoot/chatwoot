<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>


<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<img src="./.github/screenshots/dashboard.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="./.github/screenshots/dashboard-dark.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

---

Chatwoot is the modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experience. Built for scale and flexibility, Chatwoot gives you full control over your customer data while providing powerful tools to manage conversations across channels.

### ✨ Captain – AI Agent for Support

Supercharge your support with Captain, Chatwoot’s AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers. With Captain, your team can focus on complex conversations while routine questions are resolved automatically. Read more about Captain [here](https://chwt.app/captain-docs).

### 💬 Omnichannel Support Desk

Chatwoot centralizes all customer conversations into one powerful inbox, no matter where your customers reach out from. It supports live chat on your website, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS etc.

### 📚 Help center portal

Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reduce repetitive queries, and keep your support team focused on more complex issues.

### 🗂️ Other features

#### Collaboration & Productivity

- Private Notes and @mentions for internal team discussions.
- Labels to organize and categorize conversations.
- Keyboard Shortcuts and a Command Bar for quick navigation.
- Canned Responses to reply faster to frequently asked questions.
- Auto-Assignment to route conversations based on agent availability.
- Multi-lingual Support to serve customers in multiple languages.
- Custom Views and Filters for better inbox organization.
- Business Hours and Auto-Responders to manage response expectations.
- Teams and Automation tools for scaling support workflows.
- Agent Capacity Management to balance workload across the team.

#### Customer Data & Segmentation
- Contact Management with profiles and interaction history.
- Contact Segments and Notes for targeted communication.
- Campaigns to proactively engage customers.
- Custom Attributes for storing additional customer data.
- Pre-Chat Forms to collect user information before starting conversations.

#### Integrations
- Slack Integration to manage conversations directly from Slack.
- Dialogflow Integration for chatbot automation.
- Dashboard Apps to embed internal tools within Chatwoot.
- Shopify Integration to view and manage customer orders right within Chatwoot.
- Use Google Translate to translate messages from your customers in realtime.
- Create and manage Linear tickets within Chatwoot.

#### Reports & Insights
- Live View of ongoing conversations for real-time monitoring.
- Conversation, Agent, Inbox, Label, and Team Reports for operational visibility.
- CSAT Reports to measure customer satisfaction.
- Downloadable Reports for offline analysis and reporting.


## Documentation

Detailed documentation is available in the [repository wiki](https://github.com/chatwoot/chatwoot/wiki).

## Translation process

The translation process for Chatwoot web and mobile app is managed on [Crowdin](https://crowdin.com/).

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://github.com/chatwoot/chatwoot/blob/master/.env.example) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment guide](https://github.com/chatwoot/chatwoot/blob/master/README.md#deployment).

## Local development with Docker

This repo ships a **default** `docker-compose.yaml` for local development. The
`docker-compose.production.yaml` is a separate deployment target and **is not
used automatically** — Compose ignores it unless you pass `-f` explicitly.

```bash
# DEV (live reload, vite HMR, bind-mounted source)
docker compose up -d    # uses docker-compose.yaml

# PROD image (prebuilt static assets, no vite, no HMR)
docker compose -f docker-compose.production.yaml up -d --build
```

If you ran the production compose by mistake, local edits in `app/javascript/`
will not show up because there is no `vite` service and no source bind-mount.

A full guide to the running containers, the dev loop, and dev vs prod is in
[DEVELOPMENT.md](./DEVELOPMENT.md). The notes below cover the Windows-specific
gotchas.

Build `base` first so the `chatwoot:development` image exists locally, then build the dependents:

```bash
docker compose build base
docker compose build rails vite
# or, once chatwoot:development already exists locally:
docker compose build
```

After the images are built, bring the stack up with:

```bash
docker compose up
# or, with process orchestration:
overmind start -f Procfile.dev
```

Notes:
- `COMPOSE_BAKE=true` is not recommended here — on Windows it doubles the dockerfile paths (e.g. `C:\\...\\chatwoot/C:\\...
ails.Dockerfile`) and fails to build.
- The `version: '3'` key in `docker-compose.yaml` is obsolete and only produces a harmless warning; it can be removed.

### Windows gotchas (git checkout line endings)

On Windows, a global `core.autocrlf=true` rewrites shell scripts to CRLF on
checkout. A CRLF'd shebang (`#!/bin/sh
`) makes the Linux kernel fail with
`exec docker/entrypoints/rails.sh: no such file or directory`, which crashes
the `rails` and `vite` containers on `docker compose up` (they show as
"Started" then exit immediately, and are missing from `docker compose ps`).

The entrypoint scripts are baked into the built images, so fixing the files on
disk is not enough — you must rebuild the images afterward.

Fix once: this repo now contains a `.gitattributes` that pins `*.sh`, `*.rb`,
`Dockerfile`, and `bin/*` to LF to prevent the problem recurring. If you have
already-checked-out CRLF files, renormalize them and rebuild:

```bash
# convert CRLF -> LF for the scripts that run inside containers
for f in $(git ls-files '*.sh' '*.rb' 'Dockerfile' docker bin);
  do sed -i 's/
$//' "$f"; done
# then rebuild the images that bake these files in
docker compose build base rails vite sidekiq
docker compose up -d
```

Verify a file's line endings with `file <path>` — it should report
"ASCII text executable" (NOT "with CRLF line terminators").

### Running commands inside a service (e.g. `db:prepare`)

`docker compose exec <service> ...` only works if that service container is
already running. It does NOT start the container for you, so a stopped `rails`
service yields `service "rails" is not running`.

Order matters:

```bash
docker compose up -d        # start the stack first
docker compose ps           # confirm rails/vite are Up
docker compose exec rails bundle exec rails db:prepare
```

If you only need the database set up, you can also run migrations against the
running container once `postgres` is Up.

### Vite dev server (the part that usually breaks first)

The frontend is served by a **separate `vite` container** (port 3036), and Rails
proxies asset requests to it. Two config knobs in this repo make that work in
Docker and are easy to clobber:

- `config/vite.json` → `development.host: "0.0.0.0"` and `autoBuild: false`.
  `host: 0.0.0.0` makes Vite bind to all interfaces (Rails reaches it at the
  container's IPv4, not localhost). `autoBuild: false` stops Rails from running
  its *own* inline `vite build` on every request — that build hangs on this
  machine and makes `GET /` time out.
- `vite.config.ts` → `server.host: "0.0.0.0"` and `server.allowedHosts: true`.
  `allowedHosts: true` lets the dev server accept the `vite` hostname that
  Rails' ViteRuby proxy uses (without it you get HTTP 403 from inside Rails).

Do **not** set `autoBuild: true` for the Docker workflow. If you also run
Chatwoot natively (non-Docker) for dev, override these in your local env
instead of committing them.

The `vite` entrypoint (`docker/entrypoints/vite.sh`) only runs
`pnpm install --force` when `node_modules/.bin/vite` is missing. On a flaky
network a forced reinstall on every boot can hang and the dev server never
starts — if `vite` shows "Up" but nothing listens on 3036, that's why. Fix by
installing once with retry config, or just rely on the persisted `node_modules`
volume (it survives `docker compose stop/start`).

### Diagnosing a hung dashboard (`GET /` never responds)

Check the layers in order — each has a distinct symptom:

1. **Container not running** → `docker compose ps` is missing `rails`/`vite`.
   Start the stack: `docker compose up -d`.
2. **CRLF entrypoint crash** (see Windows gotchas) → `rails`/`vite` exit
   immediately, never appear in `ps`. `file docker/entrypoints/rails.sh` shows
   "with CRLF line terminators". Renormalize + rebuild images.
3. **Vite not listening** → `docker compose exec vite netstat -tln | grep 3036`
   is empty while the container is "Up". Entrypoint reinstall is hanging on the
   network; install once, don't force on every boot.
4. **Rails can't reach Vite** → from rails:
   `curl -s -m 8 http://vite:3036/vite-dev/` returns 000/403 (not 404).
   404 is fine (no page at root); 000/403 means host binding / `allowedHosts`
   is wrong — see Vite dev server section.
5. **Rails inline build loop** → `docker compose logs rails` shows repeated
   `Building with Vite ⚡️` and `vite build --mode development` PIDs pile up.
   Set `autoBuild: false` (above).
6. **Slow first boot** → `/api` and `/` can take 30–90s on first hit in dev
   (lazy class loading + Vite proxy). One 200 is enough to confirm it works.

Quick health check once the stack is up:

```bash
curl -s -m 30 -o /dev/null -w "GET / -> %{http_code}\n" http://127.0.0.1:3000/
curl -s -m 30 -o /dev/null -w "GET /api -> %{http_code}\n" http://127.0.0.1:3000/api
# both should be 200; open http://localhost:3000/ in the browser
```

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://github.com/chatwoot/chatwoot/graphs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2026, Chatwoot Inc - Released under the MIT License.
