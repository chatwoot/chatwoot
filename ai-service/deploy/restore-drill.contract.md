---
workstream: restore-drill
issue: DEV-Johnstocker/chatwoot#1
status: delivered (first drill passed); gaps open
owner: John
updated: 2026-11-08
---

# Restore drill — workstream contract

AGENTS.md §5 requires a backup before every schema change, but a backup file
existing proves nothing until it has been restored and used. This workstream
adds a repeatable restore drill. Adapted in idea from the owner's
project-reuse-toolkit backup-verification recipe (separate gates for file
integrity, completeness and a real restore); the code is new.

## Scope

- `cmd/restore-check` + `internal/restorecheck`: after a restore, run
  `Migrate`; check the `vector` extension, schema version
  (`knowledge.SchemaVersion`), every table the schema creates, minimum row
  counts and one nearest-neighbour query. JSON report with counts only.
- `deploy/restore-drill.sh`: throwaway `pgvector:pg17` container (tmpfs data,
  127.0.0.1 port, random password, always removed), Supabase `extensions`
  layout, `pg_restore --no-owner --no-privileges --exit-on-error`.
- Safety: `restore-check` reads `RESTORE_DATABASE_URL` (never `DATABASE_URL`)
  and refuses every non-loopback host, including multi-host fallbacks.

## Exclusions

- Taking backups, scheduling, retention and offsite copies (see open gaps).
- The Chatwoot database (`chatwoot`); this covers ai-service's database only.
- Running the drill in CI: backups contain customer data and stay on the VPS.

## Acceptance gates

| Gate | Command | Expected |
|---|---|---|
| Unit + guard tests | `go test ./internal/restorecheck ./internal/knowledge` | pass: loopback-only (prod hosts refused, no password in errors), min-rows parsing, every failure reported, `RequiredTables` = tables in the schema files, `SchemaVersion` = newest schema file |
| Integration | `TEST_DATABASE_URL=<local scratch> go test ./internal/restorecheck` | fresh migrated DB passes; unmet minimum reported |
| Real drill | `restore-drill.sh <latest dump> ./restore-check -min-rows kb_documents=1,kb_chunks=1,business_profiles=1` on the VPS | `RESULT: PASS`, exit 0, no drill container left |
| Corrupt backup | same, on a truncated copy | `RESTORE FAILED`, exit 2 |

## Evidence

2026-11-08, VPS (`/root/restore-drill/`), backup
`aisvc-full-20261107-230522.dump`, 804,913 bytes,
sha256 `6b580b7e697d70e82f6f2f631221757b185df8f91b308905a562f93770dd34a2`,
dumped from Postgres 17.11:

- First run failed: the Supabase dump creates schema `public` itself. Fixed in
  the script (drop the empty default schema first); this is the kind of
  surprise the drill exists to find.
- Second run: restore 0 s, total 2.4 s, `RESULT: PASS`. `Migrate` upgraded the
  restored data from schema 10 to 11. `vector` in `extensions`. Rows:
  kb_documents 106, kb_chunks 108, business_profiles 1, admin_events 9,
  kb_schema_version 1, other tables 0. Vector query ok. No container left.
- Truncated copy (400,000 bytes): `pg_restore: could not read from input
  file: end of file`, `RESTORE FAILED`, exit 2; copy shredded afterwards.
- pg16 tools cannot read this dump (`unsupported version (1.16)`), hence pg17.

2026-11-08 21:42, fresh backup at the live schema (owner's go-ahead):

- Read-only `pg_dump -Fc -n public` of Supabase production (ai-service
  database, session pooler) run on the VPS in a `pgvector:pg17` container;
  the URL came from the production container's environment through a
  root-only temp file and was never printed. The service's URL carries pgx
  pool options (`pool_max_conns`) that `pg_dump` rejects; they are stripped
  first.
- `aisvc-full-20261108-214246.dump`, 836,392 bytes, 2 s, Postgres 17.11,
  schema 11, sha256
  `a66c9387c11bcd24934dfe134c0ae30a7d8ef00c5c93b54c67ee25b0c70d6de2`, written
  to `<dump>.sha256` and checked before the drill. The container wrote the
  file mode 644 (inside the 700 backups folder); set to 600.
- Drill: `RESULT: PASS`, schema 11 before and after, kb_documents 106,
  kb_chunks 108, business_profiles 1, web_sources 2, admin_events 138;
  vector query ok; no container left.

2026-11-08 22:45, `deploy/backup.sh` (scheduled backups) tested on the VPS
from a temporary folder before review:

- Run 1 dumped, checksummed and passed the drill, then exited 1 on
  `env_file: unbound variable` (EXIT trap read a variable local to `main`).
  Fixed; run 2: exit 0, `OK ... verified`.
- **Incident:** a retention check was run against the real `/root/backups`
  with a keep-count of 3 and deleted three real full backups: 2026-11-07
  21:39 and 23:05 (schema 10) and 2026-11-08 21:42 (schema 11). The 21:42
  data is covered by the newer verified dumps; the two 2026-11-07 evening
  snapshots are lost (Supabase project backups may still hold that state).
  The test should have run on a copy. Retention was then changed from "newest
  N files" to "newest N dates" (`BACKUP_KEEP_DAYS`), so repeated runs on one
  day can no longer push older days out; `deploy/backup_test.sh` covers it.

## Open gaps

1. ~~Latest backup predates the live schema.~~ Closed 2026-11-08 by the
   fresh backup above.
2. ~~No schedule, no retention rule, backup command not in the repository.~~
   Closed by `deploy/backup.sh` and the systemd timer (README "Scheduled
   backups").
3. **No offsite copy.** Backups live on the same VPS as production; losing
   the VPS loses them. Needs the owner's choice of storage and a key.
4. **No alert on failure.** A failed run is only in the journal
   (`journalctl -u aisvc-backup.service`).
