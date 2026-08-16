# MyInvest Claude Agent for Chatwoot

This service connects one Chatwoot Agent Bot per MyInvest support account to Claude. It acknowledges signed Chatwoot webhooks immediately, queues work in Redis, retrieves only that account's approved knowledge from PostgreSQL full-text search, and replies through the Agent Bot token.

## Isolation and handoff

- `saas`, `new_academy`, and `legacy_academy` have independent Chatwoot account IDs, webhook secrets, bot tokens, and knowledge rows.
- Every retrieval query requires `tenant_key`; tests guard the negative cross-tenant path.
- Missing sources, confidence below `0.65`, explicit human requests, payment, tax, legal, or investment-advice questions open the conversation for a human.
- Chatwoot HMAC, timestamp freshness, and delivery IDs are verified before queuing. Redis deduplicates deliveries for 24 hours; PostgreSQL keeps the durable reply/handoff ledger across restarts.

## Provider

Use `ANTHROPIC_PROVIDER=bedrock` with an EU regional/Geo-EU Bedrock inference profile for EU processing. Direct Anthropic (`ANTHROPIC_PROVIDER=direct`) is supported, but its data-processing region and DPA must be reviewed separately before production use. `provider-check` performs one real, non-customer inference and prints no provider response.

For an internal OpenAI-compatible server, use `ANTHROPIC_PROVIDER=local` together with
`LOCAL_LLM_BASE_URL=http://<internal-host>:<port>/v1`, `LOCAL_LLM_MODEL`, and an exact
`LOCAL_LLM_ALLOWED_HOSTS` entry. Only explicitly allowlisted private IPs, Docker service names,
or internal hostnames are accepted; redirects, metadata/public targets, URL credentials, and
non-`/v1` paths are rejected. `LOCAL_LLM_API_KEY` is optional for a network-isolated endpoint.
Requests are time-bounded and send `stream:false` plus `think:false` for deterministic Ollama JSON.

## Bootstrap

1. Use the deployment stack's `.env`; `bootstrap.sh` creates all three account mappings without printing credentials.
2. Run `pnpm migrate` once against the separate `claude_agent` database (the container entrypoint does this idempotently).
3. Ingest approved material independently:

   ```sh
   pnpm ingest -- saas saas-help ./knowledge/saas
   pnpm ingest -- new_academy academy-website ./knowledge/academy-neu
   pnpm ingest -- legacy_academy legacy-public-site ./knowledge/academy-alt
   ```

   The authoritative inputs are the SaaS `FAQ_CATEGORIES` content from
   `App_MyInvestPro/apps/web/components/help/help-sidebar.tsx`, the new Academy's reviewed
   `Website_Software_MyInvestPro/knowledge/*.txt` files, and the public legacy Academy
   `https://www.myinvest24.de/llms-full.txt`. Prepare them as explicit `.md`/`.txt` source
   directories; the ingest command rejects customer-history bundles, JSON/NDJSON, hidden
   files, symlinks, control bytes, and files above 5 MB. Re-ingestion retires only the named
   tenant/source namespace and cannot erase other sources or learned documents.

4. Bootstrap creates one account-scoped Agent Bot per account, points it to the public signed `/_agent/webhooks/chatwoot` endpoint, and attaches it only to that account's managed website inbox.

Never put customer exports, secrets, or generated `.env` files into Git.

## Reviewed learning loop

HubSpot v2 history bundles remain separate from active knowledge. Candidate extraction verifies
the bundle manifest and message digest, pairs historical questions with human answers, removes
common personal identifiers, rejects sensitive/attachment-based pairs, and writes every result
with `target_tenant = NULL` and `status = quarantined`:

```sh
pnpm learning:extract -- /private/hubspot-v2-bundle
pnpm learning:refresh-redaction -- /private/hubspot-v2-bundle
pnpm learning:review -- approve 42 saas reviewer-id
pnpm learning:review -- publish 42 reviewer-id
```

Approval and publication are separate audited transactions. Retrieval sees only `published` and
`active` documents for the current tenant. Helpful feedback never auto-publishes anything;
negative feedback immediately retires a linked learned document and leaves a review/audit trail.
The redaction refresh updates only tenantless, unpublished quarantined candidates. Any legacy row
that cannot be matched safely is overwritten with a DLP placeholder and rejected, never deleted or
silently promoted.
