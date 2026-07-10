# rails/sidekiq containers dead with "404 / No such image" after image re-tag

- **Date**: 2026-07-10
- **Phase**: dev environment (post-upstream-sync)
- **Area**: docker

## Symptom

`chatwoot-rails-1` and `chatwoot-sidekiq-1` sat in `Exited (137)` and would not
start. Starting them manually (CLI or the Docker Desktop play button) failed —
Docker Desktop surfaces it as an **error 404**; the CLI shows the two real
errors:

```text
Error response from daemon: No such image: sha256:9855a89fb0e1...
Error response from daemon: failed to set up container networking:
  network 62369a96fe2b... not found
```

`docker compose ps -a` gave it away: both containers were 4 days old and
referenced their image **by sha256 ID**, not by tag.

## Root cause

Containers pin the exact image ID they were created from. The same day, the
`chatwoot-rails:development` tag was replaced twice (a `docker compose build`
plus the `docker commit` gem refresh after upstream bumped `Gemfile.lock`),
which left the 4-day-old image ID **untagged and pruned** — so the old
containers pointed at an image that no longer exists (`404 no such image` from
the Docker API). Additionally, an earlier
`docker compose -f ... -f docker-compose.rspec.yaml down` had removed the
shared `chatwoot_default` network, so the old containers' network reference was
dangling too. Exit code 137 was only the original SIGKILL from a host
shutdown — a red herring.

## Fix

Delete the stale containers and let compose recreate them from the current
tags (volumes/config are declared in the compose file, so nothing is lost):

```sh
docker rm chatwoot-rails-1 chatwoot-sidekiq-1 chatwoot-vite-1
docker compose up -d rails sidekiq vite
```

The recreated `vite` then crash-looped with
`Could not find websocket-driver-0.8.2` — its image also predated the upstream
`Gemfile.lock` bump. Refreshed its baked `/gems` in place (same recipe as the
rails image earlier that day):

```sh
docker create --name cw-vite-gems chatwoot-vite:development bundle install
docker cp Gemfile cw-vite-gems:/app/Gemfile
docker cp Gemfile.lock cw-vite-gems:/app/Gemfile.lock
docker start -a cw-vite-gems
docker commit --change 'CMD ["bin/vite","dev"]' cw-vite-gems chatwoot-vite:development
docker rm cw-vite-gems && docker compose up -d vite
```

Finally ran the pending upstream migration (`rails db:migrate`,
`20260629000000` from the sync) — which uncovered a separate bug, see
[2026-07-10-db-migrate-annotation-spill-into-oss-files.md](./2026-07-10-db-migrate-annotation-spill-into-oss-files.md).

## Verification

```sh
docker compose ps          # rails / sidekiq / vite all "Up"
curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/       # 200-class
curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/vite-dev/
```

## Notes / related

- **Rule of thumb:** after any re-tag/rebuild of `chatwoot-rails:development` /
  `chatwoot-vite:development`, don't `docker start` old containers — run
  `docker compose up -d <service>` (or `docker compose rm -f <service>` first)
  so containers are recreated against the current tag and network.
- After every upstream sync that touches `Gemfile.lock`, the dev images need a
  gem refresh (rebuild or the commit recipe above) before `rails`, `sidekiq`,
  `vite`, or the rspec `test` service will boot.
