```md
# Omni Desk V1 (Chatwoot CE)

Private demo: Zendesk-style agent console + website chat widget (MyRepublic Broadband SG, Customer Journey). Public fork of Chatwoot.

- Fork: https://github.com/mauricewahlberg-bit/chatwoot
- **MIT Community Edition only.** Never import, copy, call, or depend on `enterprise/`.
- Docker image: `chatwoot/chatwoot:latest-ce`
- V1 data: synthetic only. Channel: website widget only.

## Run

cp .env.example .env
# set POSTGRES_PASSWORD, REDIS_PASSWORD, SECRET_KEY_BASE, FRONTEND_URL=http://localhost:3000
# add OMNI_DESK_V1=1

docker compose -f docker-compose.omni-desk.yaml run --rm rails bundle exec rails db:chatwoot_prepare
docker compose -f docker-compose.omni-desk.yaml up -d
curl -I http://localhost:3000/api
# expect HTTP 200

## PRs
1. this — CE compose + docs
2. synthetic website thread seed
3. agent context strip: Contact attrs plan, tier (gamer|standard|fibre), account_status (active|pending_install|recontract)

Guard: block merge unless image is *-ce, zero enterprise/ in the diff, synthetic-only.
```
