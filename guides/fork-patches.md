# djc-chat Fork Patches

Index of all hand-edited files that diverge from upstream Chatwoot. Check this list before merging upstream — each patch has a marker comment at the top of the file explaining the change.

## How to find them
Every patched file starts with a `DJC-CHAT FORK PATCH` comment block. To list them all:

```bash
grep -rl "DJC-CHAT FORK PATCH" app/ config/ enterprise/ lib/ deploy/ public/ theme/ 2>/dev/null
```

## Current patches

| File | Why | Date |
|---|---|---|
| [app/javascript/dashboard/components/widgets/conversation/EmptyState/EmptyState.vue](../app/javascript/dashboard/components/widgets/conversation/EmptyState/EmptyState.vue) | Prevent "Loading inboxes" spinner wedge when zero inboxes; force onboarding view; 8s timeout fallback | 2026-04-30 |
| [app/controllers/dashboard_controller.rb](../app/controllers/dashboard_controller.rb) | Expose `EXTERNAL_LOGIN_URL` to frontend route guards | 2026-05-01 |
| [app/javascript/shared/store/globalConfig.js](../app/javascript/shared/store/globalConfig.js) | Add `externalLoginUrl` to global config state | 2026-05-01 |
| [app/javascript/dashboard/routes/index.js](../app/javascript/dashboard/routes/index.js) | Redirect unauthenticated dashboard users to external djcai-v3 login when configured | 2026-05-01 |
| [app/javascript/dashboard/routes/index.spec.js](../app/javascript/dashboard/routes/index.spec.js) | Cover dashboard external login redirect behavior | 2026-05-01 |
| [app/javascript/v3/helpers/RouteHelper.js](../app/javascript/v3/helpers/RouteHelper.js) | Redirect direct Chatwoot login page visits to external login while preserving SSO token login URLs | 2026-05-01 |
| [app/javascript/v3/helpers/specs/RouteHelper.spec.js](../app/javascript/v3/helpers/specs/RouteHelper.spec.js) | Cover v3 login-route external redirect behavior | 2026-05-01 |
| [app/javascript/v3/views/login/Index.vue](../app/javascript/v3/views/login/Index.vue) | Send failed SSO token retries back to external login when configured | 2026-05-01 |

## Config-only changes (no marker comment)

These are config tweaks — diff them on upstream merges:

- [config/installation_config.yml](../config/installation_config.yml) — added `EXTERNAL_LOGIN_URL`; set it to `https://app.simplynice.ai/chat-login` to disable the direct Chatwoot login page while preserving SSO-token login handoff URLs
- [config/installation_config.yml](../config/installation_config.yml) — `INSTALLATION_NAME` and `BRAND_NAME` defaults changed to `DJC Chat`, both unlocked
- [app/javascript/dashboard/i18n/locale/en/](../app/javascript/dashboard/i18n/locale/en/) — bulk replaced "Chatwoot" → "DJC Chat" across 13 English locale files (2026-04-30). On upstream merge: re-run `find app/javascript/dashboard/i18n/locale/en -type f -name "*.json" -exec sed -i 's/Chatwoot/DJC Chat/g' {} +`
- [app/javascript/widget/i18n/locale/en.json](../app/javascript/widget/i18n/locale/en.json) — "Powered by DJC Chat" in widget
- [app/javascript/survey/i18n/locale/en.json](../app/javascript/survey/i18n/locale/en.json) — "Powered by DJC Chat" in survey
- [.github/workflows/publish_foss_docker.yml](../.github/workflows/publish_foss_docker.yml) — fork guard, matrix `pair`
- [.github/workflows/publish_ee_docker.yml](../.github/workflows/publish_ee_docker.yml) — fork guard, matrix `pair`
- [.github/workflows/frontend-fe.yml](../.github/workflows/frontend-fe.yml) — manual dispatch only
- [.github/workflows/run_foss_spec.yml](../.github/workflows/run_foss_spec.yml) — manual dispatch only
- [.github/workflows/run_mfa_spec.yml](../.github/workflows/run_mfa_spec.yml) — manual dispatch only
- [.github/workflows/nightly_installer.yml](../.github/workflows/nightly_installer.yml) — manual dispatch only
- [.github/workflows/stale.yml](../.github/workflows/stale.yml) — manual dispatch only
- [.github/workflows/lock.yml](../.github/workflows/lock.yml) — manual dispatch only

## New files (won't conflict)

- [.github/workflows/docker-publish.yml](../.github/workflows/docker-publish.yml)
- [scripts/docker-build-push.sh](../scripts/docker-build-push.sh)
- [deploy/docker-compose.yaml](../deploy/docker-compose.yaml)
- [deploy/Caddyfile](../deploy/Caddyfile)
- [deploy/.env.example](../deploy/.env.example) (gitignored) — documents `EXTERNAL_LOGIN_URL=https://app.simplynice.ai/chat-login`
- [deploy/branding/](../deploy/branding/)
- [guides/](../guides/) (gitignored)

## Adding a new patch — convention

When editing an upstream file:

1. Add this header at the top (adapt for `<!-- -->`, `#`, `//`, or `/* */` comment style):

   ```
   ============================================================================
   DJC-CHAT FORK PATCH — see guides/fork-patches.md for full list
   ----------------------------------------------------------------------------
   Date:       YYYY-MM-DD
   Why:        <one-paragraph reason this diverges from upstream>
   Changes:    1. <bullet list of behavioural changes>
               2. ...
   Merge tip:  <hints for resolving future upstream merge conflicts>
   ============================================================================
   ```

2. Add a row to the table above with file path + reason + date.

3. Commit with prefix `fork: ` so the history is greppable: `git log --oneline | grep '^[a-f0-9]* fork:'`
