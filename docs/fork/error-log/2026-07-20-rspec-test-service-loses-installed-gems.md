# rspec `test` service can't see installed gems — `bundle install` evaporates on every `run --rm`

- **Date**: 2026-07-20
- **Phase**: dev environment (post-upstream-sync)
- **Area**: docker

## Symptom

The documented spec command from `CLAUDE.md` failed immediately after the
2026-07-20 upstream sync:

```text
bundler: failed to load command: rspec (/gems/ruby/3.4.0/bin/rspec)
/usr/local/bundle/gems/bundler-2.5.16/lib/bundler/definition.rb:600:in
  'Bundler::Definition#materialize': Could not find datadog-2.38.0,
  datadog-ruby_core_source-3.5.3, libdatadog-36.0.0.1.0, libddwaf-1.30.0.0.2,
  rails-html-sanitizer-1.7.1, loofah-2.25.2 in locally installed gems
  (Bundler::GemNotFound)
```

The confusing part: running `bundle install` in the `test` service **succeeded**
(`Bundle complete! 151 Gemfile dependencies, 377 gems now installed.`), and the
very next `run --rm test bundle exec rspec` failed with the *same* six missing
gems.

## Root cause

Two separate things, and the second is the one that makes it look unfixable.

1. Upstream's `chore(deps): address bundle audit vulnerabilities (#15055)`
   (merged in the 2026-07-20 sync) bumped `Gemfile.lock`, so the baked `/gems`
   in `chatwoot-rails:development` went stale — the recurring post-sync problem
   already noted in
   [2026-07-10-stale-containers-404-after-image-retag.md](./2026-07-10-stale-containers-404-after-image-retag.md).

2. **The `test` service mounts the wrong path, so `bundle install` cannot
   persist.** In the image:

   ```text
   BUNDLE_PATH=/gems                 <- where bundler actually installs
   GEM_HOME=/usr/local/bundle        <- what docker-compose.rspec.yaml mounts
   ```

   `docker-compose.rspec.yaml` declares `- bundle:/usr/local/bundle`, but
   bundler writes to `BUNDLE_PATH=/gems`, which is **not** a volume — it lives
   in the container's writable layer. With `run --rm`, that layer is destroyed
   on exit, so every install is thrown away and the next container starts stale
   again. The install genuinely succeeded; it just had nowhere durable to land.

## Fix

**Workaround actually used** (install and run in a *single* container, so the
gems survive long enough to be used):

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  sh -c "bundle install && bundle exec rails db:create db:schema:load && \
         bundle exec rspec spec/custom/..."
```

Note `sh`, not `bash` — `bash` is **absent** from this image, and with
`entrypoint: ""` a `bash -c` invocation dies with:

```text
exec: "bash": executable file not found in $PATH
```

**Durable fix (recommended, NOT yet applied)** — pick one:

- Rebuild so the new gems are baked in: `docker compose build rails`
  (the `test` service reuses `chatwoot-rails:development`); or
- Add `/gems` to the volume list in `docker-compose.rspec.yaml` so installs
  persist across `run --rm`, e.g. `- gems:/gems`.

Until one of those lands, the documented one-liner in `CLAUDE.md` will keep
failing after any sync that touches `Gemfile.lock`.

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  sh -c "bundle install > /dev/null 2>&1 && \
         bundle exec rails db:create db:schema:load > /dev/null 2>&1 && \
         bundle exec rspec spec/custom/controllers/api/v1/accounts/assignable_agents_controller_spec.rb \
                           spec/custom/models/inbox_assignable_agents_spec.rb \
                           spec/custom/models/super_admin_privilege_separation_spec.rb"
# -> 7 examples, 0 failures
```

## Notes / related

- **This was a recurrence, and the log already warned about it.**
  [2026-07-10-stale-containers-404-after-image-retag.md](./2026-07-10-stale-containers-404-after-image-retag.md)
  closes with exactly this rule: *"After every upstream sync that touches
  `Gemfile.lock`, the dev images need a gem refresh … before `rails`, `sidekiq`,
  `vite`, or the rspec `test` service will boot."* Per `README.md` rule 5, a
  grep **before** debugging would have surfaced it — but note that
  `rg -i "GemNotFound"` would **not** have: the 07-10 entry quotes bundler's
  other phrasing (`Could not find websocket-driver-0.8.2`). The queries that do
  hit it are `"Could not find"`, `"Gemfile.lock"`, or `"bundle install"`. Grep a
  distinctive *phrase* from the error, not just the exception class name.
  What is new here is *why* the obvious remedy (`bundle install` in the `test`
  service) silently does nothing — the `BUNDLE_PATH` / mounted-volume mismatch
  above.
- Post-sync checklist gap: [`UPSTREAM_SYNC.md`](../UPSTREAM_SYNC.md) §3b lists
  overlay-binding and branding-regression checks, but nothing about refreshing
  dev images when the sync moves `Gemfile.lock`. Worth adding there, since that
  is the doc consulted during a sync.
- Do not "fix" this by pointing `BUNDLE_PATH` at `/usr/local/bundle`: that is
  `GEM_HOME` (bundler's own install location) and the image deliberately keeps
  application gems separate in `/gems`.
