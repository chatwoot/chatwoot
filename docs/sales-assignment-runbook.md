# Sales assignment and daily session logout

This fork includes upstream snapshot `e212425e7b` on top of `2abc9f5f0e` (including WhatsApp product cards).

## Configure the approved operation

The initial target is account 2, inbox 20, custom role `Vendedor`. Resolve the role ID inside that account before running. The command previews by default:

```sh
ACCOUNT_ID=2 INBOX_ID=20 CUSTOM_ROLE_ID=<role-id> POLICY_NAME='Armazém WhatsApp — vendedores' \
  bundle exec rails runner script/configure_sales_assignment.rb
```

Add `APPLY=true` to apply the reviewed preview. Run it again when onboarding eligible sellers so their native capacity policy is set. Existing capacity policies on sellers must be reconciled before applying; the command refuses to replace them silently.

The configuration uses online sellers only, balanced open workload within the inbox, 100 open conversations per seller, and five automatic assignments per rolling hour. Existing owners and manual assignments are preserved. Conversations wait when no eligible seller is available. Team restrictions still apply. The queue prefers the newest incoming customer message, falling back to conversation creation when no incoming message exists; notes and agent replies do not raise priority. The seven-day inactivity exclusion remains enabled.

Business hours use the inbox calendar: Monday-Friday 09:00-19:00, Saturday-Sunday 10:00-18:00, America/Sao_Paulo. Policies with business-hours restrictions are swept each minute; other policies retain their 30-minute sweep.

## Daily logout

Internal account setting `daily_agent_logout` contains `enabled`, `inbox_id`, `custom_role_id`, `time`, and `timezone`. It is not exposed by the public account settings API. The scheduler checks each minute and records `last_completed_on` transactionally with revocation.

At 20:00 the selected sellers' pre-cutoff web/mobile sessions are revoked. API access tokens and integration credentials are preserved. Browser events name the revoked clients so a newly opened session is not logged out by a delayed notification. New login remains allowed. Disable by setting only `daily_agent_logout.enabled` to false, preserving unrelated settings.

## Release gates

1. Restore a current production database backup to an isolated database and Redis. Block external HTTP and keep workers disabled during rehearsal.
2. Apply upstream and fork migrations. Compare conversation/message/blob counts and custom tables before and after. Exercise the setup command in preview and apply modes, then repeat it to verify idempotency.
3. Pass assignment, concurrency, auth/session, Captain, WhatsApp cards, CRM, ERP and conversion checks; build assets and inspect the policy form and logout in a browser.
4. Capture a fresh consistent database backup and attachment-volume backup, with checksums and restore proof. Preserve the previous image digest and service configuration without publishing secrets.
5. Publish one immutable image and deploy it to app, worker and realtime worker; run migrations once with writes paused, and verify all services use the same image before reopening traffic.
6. Apply the production configuration and reread policies, calendar, seller capacity associations, logout scope and Captain flags. Observe queue counts, assignment errors, rates and sessions through the first complete business period.

## Rollback

Disable the inbox's automatic assignment and scheduled logout to stop the new operational behavior. Do not clear existing owners. The Captain custom-tool migration is irreversible: database rollback requires restoring the backup, not `db:rollback`. Before restoring after traffic resumed, capture and reconcile new writes so messages and orders are not lost. Restore the attachment archive into a separate volume first, validate it, then switch to it only if required.
