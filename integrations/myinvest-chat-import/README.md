# MyInvest Chat history import

This is a callback-free, one-time history importer for the pinned Chatwoot v4.16.2 deployment. One bundle belongs to exactly one of `saas`, `new_academy`, or `legacy_academy`. It creates or resolves a dedicated bot-free `History Import` API inbox, imports every conversation as resolved/read, and preserves source/provenance metadata without using it for routing.

The runner uses `insert_all!`, `DataImport`, and `DataImportMapping`; stable source identities are tenant-scoped HMACs. A PostgreSQL advisory lock serializes imports per tenant, each conversation and its messages are atomic, retries are idempotent, and changed payloads for an existing source identity fail closed. No record body or external ID is logged.

## Bundle v1

The root contains `manifest.json`, `contacts.ndjson`, `conversations.ndjson`, and `messages.ndjson`. The manifest and record contracts are in [`schema/`](schema/). Manifest SHA-256 values are calculated over the exact file bytes. Files must be regular, non-symlink files in the bundle root; v1 rejects every attachment, including external URLs. All input must be valid UTF-8 without NUL bytes, and message content is imported as plaintext with a 150,000-character limit.

`knowledge_import` must be `false`. This code has no Claude-agent database integration or credentials and never writes to the knowledge store. If selected conversations should later become knowledge, that is a separate, reviewed export and ingestion process.

## Validate without writes

```sh
ruby -I integrations/myinvest-chat-import/lib -r myinvest_chat_import -e \
  'bundle = MyinvestChatImport::Bundle.load(ARGV.fetch(0)); puts JSON.generate(tenant_key: bundle.tenant_key, contacts: bundle.contacts.length, conversations: bundle.conversations.length, messages: bundle.messages.length)' \
  /absolute/path/to/bundle
```

## Run once in the stock container

Generate and retain a random HMAC key in the deployment secret store. The MyInvest deployment creates it once as `IMPORT_ID_HMAC_KEY` and maps it to the runner-only `CHAT_IMPORT_HMAC_KEY`; it is never passed to the long-running Chatwoot or Claude services. The runner and bundle are mounted read-only; only the existing Chatwoot database is writable. Run a verified backup first.

```sh
CHAT_IMPORT_HMAC_KEY="$(openssl rand -hex 32)"
export CHAT_IMPORT_HMAC_KEY
docker compose --env-file deployment/myinvest/.env -f deployment/myinvest/compose.yaml run --rm \
  -e CHAT_IMPORT_HMAC_KEY \
  -v "$PWD/integrations/myinvest-chat-import:/myinvest-chat-import:ro" \
  -v "/absolute/path/to/bundle:/history-bundle:ro" \
  rails bundle exec rails runner /myinvest-chat-import/bin/import.rb /history-bundle
```

Reuse the same HMAC key for every retry and future snapshot from the same source namespace. Changing the key disables deduplication and is therefore unsafe. For the managed deployment, prefer `deployment/myinvest/scripts/import-chat-history.sh`; it requires an exact bundle confirmation, performs an automatic second idempotency run, verifies the imported ledger/inbox, and proves that the knowledge-document count did not change.

## Verify

The runner returns only tenant and aggregate counts. A second run must report all records as `reused`. The following callback-free query checks the ledger and imported record counts without exposing chat content:

```sh
docker compose --env-file deployment/myinvest/.env -f deployment/myinvest/compose.yaml exec rails bundle exec rails runner '
account = Account.where("custom_attributes ->> ? = ?", "myinvest_tenant_key", "new_academy").first!
inbox = account.inboxes.find_by!(name: "History Import", channel_type: "Channel::Api")
abort "unsafe inbox" if inbox.channel.webhook_url.present? || AgentBotInbox.where(inbox_id: inbox.id).exists?
counts = { contacts: inbox.contact_inboxes.count, conversations: inbox.conversations.resolved.count, messages: inbox.messages.count }
puts JSON.generate(counts)
'
```

Run unit and syntax checks with:

```sh
ruby integrations/myinvest-chat-import/test/importer_test.rb
find integrations/myinvest-chat-import -name '*.rb' -print0 | xargs -0 -n1 ruby -c
```
