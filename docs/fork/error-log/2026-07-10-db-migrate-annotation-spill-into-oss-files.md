# rails db:migrate auto-annotates models and dirties OSS/enterprise files

- **Date**: 2026-07-10
- **Phase**: dev environment (post-upstream-sync)
- **Area**: db / docker

## Symptom

Running the pending upstream migration after the sync:

```text
$ docker compose exec rails bundle exec rails db:migrate
...
Annotating models
Annotated (6): app/models/category.rb, app/models/message.rb,
  app/models/platform_banner.rb, enterprise/app/models/call.rb,
  enterprise/app/models/captain/document.rb, enterprise/app/models/company.rb
```

Six OSS/enterprise files the fork must not touch showed up as modified —
including the exact four whose annotation churn had been found and reverted in
that morning's audit (commit `04a5e70`). This is the root cause of that churn:
it recurs on **every** `db:migrate` in dev.

## Root cause

The `annotaterb` gem hooks Rails' db tasks in development
(`lib/tasks/annotate_rb.rake`) and re-annotates **every** model whose schema
comment differs from the live dev DB — not just models touched by the migration
that ran. The dev (Neon) DB's column ordering/metadata legitimately drifts from
the annotation text upstream committed (upstream generates against its own DB),
so each migrate run "corrects" upstream's comment blocks and creates diffs in
files that will textually conflict on future upstream pulls
(`UPSTREAM_DIFF.md` §8's annotation-spill warning, now observed live).

## Fix

Reverted the six files to upstream text (`git checkout -- <files>`), then
disabled the migrate hook via the gem's own escape hatch — set in the fork-owned
`docker-compose.yaml` `rails` service (no OSS edit; the rake file explicitly
documents the variable):

```yaml
environment:
  ANNOTATERB_SKIP_ON_DB_TASKS: "1"
```

Trade-off, on purpose: annotations are now frozen at upstream's committed text.
After adding a **fork** migration, update annotations for just the fork-touched
models manually (e.g. `bundle exec annotaterb models app/models/webhook.rb ...`)
instead of letting the hook sweep the whole tree.

## Verification

```sh
docker compose up -d rails        # recreate with the new env
docker compose exec rails bundle exec rails db:migrate
git status --short -- app enterprise   # -> empty (no "Annotating models" run)
```

## Notes / related

- Root cause of the churn documented in
  `UPSTREAM_DIFF.md` §3/§8 and reverted in commit `04a5e70`.
- Found while fixing
  [2026-07-10-stale-containers-404-after-image-retag.md](./2026-07-10-stale-containers-404-after-image-retag.md)
  (the migrate that triggered it was the post-sync pending migration).
