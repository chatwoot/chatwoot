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

## Open gaps

1. **Latest backup predates the live schema.** The newest full backup
   (2026-11-07 23:05) is at schema 10; production has run schema 11 since
   2026-11-08. A restore today would lose everything written since.
2. **Backups are manual and live on the same VPS** as production, with no
   checksum written at backup time, no schedule, no retention rule and no
   offsite copy. Losing the VPS loses the backups.
3. The backup command itself is not in the repository.
