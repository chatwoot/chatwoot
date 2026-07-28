# db/schema.rb churns after running db tasks against Neon (PostgreSQL 18)

- **Date**: 2026-07-27
- **Phase**: Phase 0 (dev environment)
- **Area**: db

## Symptom

After `rails db:chatwoot_prepare` against Neon, `git status` showed
`db/schema.rb` modified even though no migration was added:

```text
 M db/schema.rb
 db/schema.rb | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
```

The diff contains no schema change — the version line is untouched
(`2026_07_18_000000`). Only two cosmetic things move:

```diff
-    t.index ["account_id"], name: "index_captain_faq_suggestions_on_account_id"
     t.index ["account_id", "assistant_id", "status", "language"], name: "idx_cap_..."
+    t.index ["account_id"], name: "index_captain_faq_suggestions_on_account_id"
```

```diff
-    ... where: "(account_id IS NOT NULL) AND (inbox_id IS NULL)"
+    ... where: "((account_id IS NOT NULL) AND (inbox_id IS NULL))"
```

## Root cause

The committed `db/schema.rb` was dumped from PostgreSQL 16. Neon runs
**PostgreSQL 18**, which reports index metadata in a different order and
normalizes partial-index `WHERE` expressions with extra parentheses. The schema
dumper faithfully writes what the *connected server* reports, so any db task
that triggers a dump rewrites those lines.

It is server-version drift, not a real schema difference. The database is
correct either way.

## Fix

Revert it. Do not commit:

```sh
git checkout -- db/schema.rb
```

`db/schema.rb` is not read at runtime (it is only used by `db:schema:load`), so
reverting has no effect on the running app — verified by re-checking
`/api` after the revert (`data_services: ok`).

Committing this churn would be actively harmful: `db/schema.rb` is the fork's
largest textual-conflict surface with upstream (`docs/fork/UPSTREAM_DIFF.md`),
and re-ordering hundreds of index lines to match PG18 would conflict on every
future upstream merge, forever.

**When you add a real fork migration**, commit only the lines your migration
actually changed — the version line plus your new table/column — and revert the
PG18 reordering noise in the same file before committing.

## Verification

```sh
git diff --stat db/schema.rb    # => no output; clean tree
curl -s http://localhost:3000/api
# {"version":"4.16.1","queue_services":"ok","data_services":"ok"}
```

## Notes / related

- Related but distinct: [2026-07-10 — rails db:migrate auto-annotates models and dirties OSS/enterprise files](./2026-07-10-db-migrate-annotation-spill-into-oss-files.md)
  (annotaterb spill, guarded by `ANNOTATERB_SKIP_ON_DB_TASKS=1`). That guard
  stops *model annotation* spill; it does not stop *schema dump* churn, which is
  what this entry covers.
- [2026-07-16 — Rails 500s on PendingMigrationError after the upstream merge; migrating churns schema.rb](./2026-07-16-pending-migrations-500-and-schema-churn.md)
  observed the churn; this entry identifies the PG-version cause.
- Setup runbook: [DEV_SETUP.md](../DEV_SETUP.md)
