# Rails 500s on PendingMigrationError after the upstream merge; migrating churns schema.rb

- **Date**: 2026-07-16
- **Phase**: dev environment (post-upstream-sync)
- **Area**: db / docker

## Symptom

Every page on the Chatwoot dev server returned **500** — for hours, unnoticed,
because nothing else depends on it locally:

```text
$ curl -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/
500

$ docker logs chatwoot-rails-1 --tail 60
ActiveRecord::PendingMigrationError (
```

Two migrations were `down`:

```text
  down    20260623000000  Add draft columns to articles
  down    20260713184351  Create captain faq suggestions
```

The second is dated the day of the last upstream merge (`ab8e9c1`, 2026-07-13) —
it arrived **with the pull**. The DB was behind the code, and `db/schema.rb`
already declared `version: 2026_07_13_184351`, i.e. **the schema file was ahead of
the database**.

## Root cause

Merging upstream brings migration *files*; it does not run them. Nothing in the
dev flow applies them automatically, and the failure surfaces only as a generic
500 on the web tier — the containers stay **`Up`** and healthy-looking, so
`docker ps` says everything is fine while the app serves nothing.

## Fix

```sh
docker exec chatwoot-rails-1 bundle exec rails db:migrate
```

```text
== 20260623000000 AddDraftColumnsToArticles: migrated (0.2660s)
== 20260713184351 CreateCaptainFaqSuggestions: migrated (1.3608s)
```

### The annotation guard held ✅

`2026-07-10-db-migrate-annotation-spill-into-oss-files.md` predicted this migrate
would re-annotate OSS/enterprise models. It did not — the guard is live in the
running container:

```sh
$ docker exec chatwoot-rails-1 printenv ANNOTATERB_SKIP_ON_DB_TASKS
1
$ git status --short -- app enterprise
            # empty ✅
```

### But `db/schema.rb` still churned — reverted

```text
 db/schema.rb | 2 +-
-    t.index ["account_id"], name: "index_captain_faq_suggestions_on_account_id"
     t.index ["account_id", "assistant_id", "status", "language"], name: "idx_…"
+    t.index ["account_id"], name: "index_captain_faq_suggestions_on_account_id"
```

Two index lines **swapped order** on `captain_faq_suggestions`. Same version, same
set of indexes — semantically a no-op. It is the dev-DB metadata drift described in
the 07-10 entry, leaking through a channel the annotaterb guard does not cover:
Rails' own schema dumper.

`db/schema.rb` is `UPSTREAM_DIFF.md`'s **largest conflict surface**, so a
cosmetic diff there is a future merge conflict for zero benefit. Reverted, exactly
as the 07-10 entry does for annotated files:

```sh
git checkout -- db/schema.rb
```

The migrations are unaffected — `schema.rb` is a **dump**, not the source of truth
for what has already been applied. Confirmed after the revert:

```text
   up     20260623000000  Add draft columns to articles
   up     20260713184351  Create captain faq suggestions
```

**Net divergence from this migrate: zero.** No upstream file changed.

## Verification

```sh
docker exec chatwoot-rails-1 bundle exec rails db:migrate:status | grep -E "20260623000000|20260713184351"
#   up     20260623000000 …
#   up     20260713184351 …

git status --short          # empty

curl -o /dev/null -w '%{http_code} %{time_total}s\n' --max-time 90 http://127.0.0.1:3000/
# 200 3.7s
curl -o /dev/null -w '%{http_code}\n' --max-time 90 https://mesh-crm.mujibulhaquetanim.dev/
# 200
```

⚠️ **Use a generous curl timeout.** The first request after migrating took **88
seconds** (cold Vite compile) and returned `000` on a 15s timeout — which looks
like "now it's completely dead" rather than "it's compiling". The rails log said
`Completed 200 OK in 88507ms` the whole time. Read the log before re-diagnosing.

## Notes / related

- `2026-07-10-db-migrate-annotation-spill-into-oss-files.md` — the guard that made
  this migrate safe; the schema-dumper churn is the same drift via another route.
- `UPSTREAM_DIFF.md` §1 — `db/schema.rb` as the top conflict surface.
- **After every upstream merge, run `db:migrate` and then `git checkout --
  db/schema.rb` if the only diff is ordering.** Consider making that a step in
  `UPSTREAM_SYNC.md`: the merge is not finished when the merge commit lands, it is
  finished when the DB matches and the tree is clean again.
- A green `docker ps` proves the container is **up**, not that the app **works**.
  `curl` the web tier after any merge.
