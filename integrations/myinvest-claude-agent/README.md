# MyInvest Claude Agent for Chatwoot

This service connects one Chatwoot Agent Bot per MyInvest support account to Claude. It acknowledges signed Chatwoot webhooks immediately, queues work in Redis, retrieves only that account's approved knowledge from PostgreSQL full-text search, and replies through the Agent Bot token.

## Isolation and handoff

- `saas`, `new_academy`, and `legacy_academy` have independent Chatwoot account IDs, webhook secrets, bot tokens, and knowledge rows.
- Every retrieval query requires `tenant_key`; tests guard the negative cross-tenant path.
- Missing sources, confidence below `0.65`, explicit human requests, payment, tax, legal, or investment-advice questions open the conversation for a human.
- Chatwoot HMAC, timestamp freshness, and delivery IDs are verified before queuing. Redis deduplicates deliveries for 24 hours; PostgreSQL keeps the durable reply/handoff ledger across restarts.

## Provider

Use `ANTHROPIC_PROVIDER=bedrock` with an EU regional/Geo-EU Bedrock inference profile for EU processing. Direct Anthropic (`ANTHROPIC_PROVIDER=direct`) is supported, but its data-processing region and DPA must be reviewed separately before production use. `provider-check` performs one real, non-customer inference and prints no provider response.

## Bootstrap

1. Use the deployment stack's `.env`; `bootstrap.sh` creates all three account mappings without printing credentials.
2. Run `pnpm migrate` once against the separate `claude_agent` database (the container entrypoint does this idempotently).
3. Ingest approved material independently:

   ```sh
   pnpm ingest -- saas ./knowledge/saas
   pnpm ingest -- new_academy ./knowledge/academy-neu
   pnpm ingest -- legacy_academy ./knowledge/academy-alt
   ```

4. Bootstrap creates one account-scoped Agent Bot per account, points it to the public signed `/_agent/webhooks/chatwoot` endpoint, and attaches it only to that account's managed website inbox.

Never put customer exports, secrets, or generated `.env` files into Git. Knowledge ingestion replaces one tenant atomically and cannot touch another tenant.
