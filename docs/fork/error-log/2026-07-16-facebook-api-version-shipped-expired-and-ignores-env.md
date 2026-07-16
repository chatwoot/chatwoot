# FACEBOOK_API_VERSION ships expired (v18.0) and `.env` cannot change it

- **Date**: 2026-07-16
- **Phase**: Phase 6 (Meta channel onboarding) — found while writing the two-app
  Meta setup guide in `meta-saas`
- **Area**: backend / config

## Symptom

No error. Nothing fails. Two silent problems stacked:

1. Chatwoot calls Meta on **`v18.0`**, which **expired 2026-01-26**. No warning is
   logged, no request fails.
2. Setting `FACEBOOK_API_VERSION=v25.0` in `.env` and recreating the containers
   **changes nothing** — while every other `FB_*` key in the same `.env` works.

```text
# effective value, despite .env saying v25.0:
GlobalConfigService.load('FACEBOOK_API_VERSION', 'v18.0')  # => "v18.0"
```

## Root cause

### ① Expired versions fail by succeeding

Meta: *"once a version is no longer usable, any calls made to it will be defaulted
to the next oldest, usable version"*
([versioning](https://developers.facebook.com/docs/graph-api/guides/versioning)).

So `v18.0` silently executes as **v20.0** (today's oldest usable) — semantics
nobody chose, with nothing to alert on: `X-Ad-Api-Version-Warning` is documented
for the **Marketing API only**. Two aggravators:

- Meta's Marketing API docs say auto-upgrade is **not** applied to endpoints hit by
  the newer version's breaking changes — those **do** fail. Whether that carve-out
  applies to core Graph is **undocumented**.
- **The floor moves.** v20.0 expires **2026-09-24**; after that these calls land on
  v21.0. The pin is decorative.

### ② `.env` is never read for this key

`lib/global_config_service.rb` reads the **DB row first**:

```ruby
config = GlobalConfig.get(config_key)[config_key]
return config if config.present?          # ← ENV is never reached
config_value = ENV.fetch(config_key) { default_value }
```

Whether `.env` works is decided per key by whether `installation_config.yml` ships
a `value:` — and it differs **within the same file**:

| Key | `value:` in yml | Row after seed | `.env` works? |
| --- | --- | --- | --- |
| `FB_APP_ID`, `FB_APP_SECRET`, `FB_VERIFY_TOKEN`, `IG_VERIFY_TOKEN` | absent | blank | **yes** |
| `FACEBOOK_API_VERSION` | `'v18.0'` | `v18.0` | **no** |

Editing the yml doesn't help either: `ConfigLoader` runs `reconcile_only_new: true`
— it creates missing rows and **never updates existing ones**. The ENV path is an
explicit legacy shim (*"To support migrating existing instance relying on env
variables — TODO: deprecate this later down the line"*), not the contract.

Same shape as `2026-07-10-sso-flag-leaked-from-dev-env-into-specs.md`: that entry
was bitten by the ENV fallback **firing** when it shouldn't; this one by the ENV
fallback **not firing** when you expect it. Same resolver, opposite failure.

## Fix

**Config only — no code changed.** Set it in **Super Admin → Settings →
Configuration**: `FACEBOOK_API_VERSION` = `v25.0` (current; released 2026-02-18;
matches `meta-saas`'s `META_GRAPH_VERSION`). The key is `locked: false`, and the
row is the only thing read.

Docs corrected in the same pass — `docs/fork/META_CHANNEL_ONBOARDING.md` claimed
*"this fork's send path defaults to v25.0"*, which was **false**: `v25.0` appears
nowhere in this codebase.

### Deliberately NOT fixed (would touch upstream core)

These need code, and the fork rule is *do not modify Chatwoot's core flow; stay
merge-clean with upstream*. Documented instead:

| Hardcode | File | Rides |
| --- | --- | --- |
| `v11.0` | `app/services/instagram/messenger/send_on_instagram_service.rb:17` | v20.0 |
| `v13.0` | `app/services/whatsapp/providers/whatsapp_cloud_service.rb:88` | v20.0 |
| `v14.0` | `app/services/whatsapp/providers/whatsapp_cloud_service.rb:117` | v20.0 |

- The IG one has **no `prepend_mod_with` hook**, so a `custom/` overlay would
  require adding a line to an upstream file **and** duplicating `send_message`
  wholesale — it drifts the moment upstream edits that method.
- The WhatsApp file **does** have a hook (`:252`), so an overlay there needs zero
  upstream edits — viable if/when WhatsApp ships.
- **Upstream has not fixed any of them** (verified against `chatwoot/chatwoot`
  `develop`, 2026-07-16). Open PR **#9811** *"chore: Update Meta Graph API versions"*
  covers **only the WhatsApp files** — and has been open since **2024-07-20**. Do
  not wait for it.

**Trigger to revisit: 2026-09-24**, when v20.0 expires and the silent floor moves
again.

## Verification

Verify the **effective** value, not the input you typed:

```sh
docker compose run --rm rails bundle exec rails runner \
  'puts GlobalConfigService.load("FACEBOOK_API_VERSION", "v18.0")'
# => v25.0
```

> Not run in this session: no Ruby/bundler on the host and Docker was erroring
> (`/usr/bin/docker: Input/output error`). The change is a Super Admin config edit
> plus docs — **run the above after setting it.**

## Notes / related

- `docs/fork/META_CHANNEL_ONBOARDING.md` — the corrected `FACEBOOK_API_VERSION` row
  and the full `.env` warning.
- `meta-saas`: `docs/troubleshooting/062-facebook-api-version-cannot-be-set-via-env.md`
  and `docs/integration/meta-two-apps-setup.md` (the two-Meta-app split).
- Upstream open PR [#14791](https://github.com/chatwoot/chatwoot/pull/14791)
  *"feat(instagram): support post/reel comment management"* adds native IG comment
  ingestion — but only for the **Instagram Login** channel
  (`instagram_business_manage_comments`), **not** the Facebook-Login IG path. It
  does not overlap the comment automation in `meta-saas`, which runs on its own
  Meta app.
