# Super Admin — access, management, and protection

The **Super Admin console** (`/super_admin`) is the platform operator's control
surface for the whole Chatwoot instance — separate from any tenant/vendor dashboard.
This is the most sensitive surface in the system: it can read and change **every
tenant's** data and can mint the credentials that provision everything. Treat access
to it as root access to the platform.

> **One-line rule:** Super Admin is for **you, the platform operator**, only. No
> vendor, agent, or tenant user can ever reach it. Keep it up, lock it down, and
> restrict it at the network layer.

## 1. What it controls (blast radius)

Routes live under `namespace :super_admin` in `config/routes.rb`, guarded by
`authenticate_super_admin!` (`app/controllers/super_admin/application_controller.rb`).
It manages, for the **entire instance**:

| Area | Route | Why it's sensitive |
| --- | --- | --- |
| **Accounts** | `super_admin/accounts` (+ `seed`, `reset_cache`) | Create/edit/**delete** any tenant account; reset caches. |
| **Users** | `super_admin/users` | Create/edit/delete any user across all tenants; **create other Super Admins** (`type: 'SuperAdmin'`). |
| **Account users** | `super_admin/account_users` | Attach/detach any user to any account with any role. |
| **Platform Apps** | `super_admin/platform_apps` | **Creates the `PLATFORM_TOKEN`** — the master provisioning credential the control plane (meta-saas/NestJS) uses to create accounts, users, SSO links, and set `accounts.limits`. Anyone here can mint or read it. |
| **Access tokens** | `super_admin/access_tokens` | View API access tokens. |
| **Installation configs** | `super_admin/installation_configs`, `app_config` | Change instance-wide settings — including `ENABLE_SSO_ONLY_LOGIN`, `ENABLE_ACCOUNT_SIGNUP`, `EXTERNAL_LOGIN_URL`, SMTP, storage. **Can disable the SSO-only lockdown.** |
| **Agent bots** | `super_admin/agent_bots` | Global agent bots. |
| **Instance status / settings** | `super_admin/instance_status`, `settings` | Health + instance settings. |
| **Sidekiq** | `/monitoring/sidekiq` (`authenticated :super_admin`) | Background-job queues (retry/kill jobs, see payloads). |

Because it owns **Platform Apps** and **installation configs**, a compromised Super
Admin can bypass every other control in this fork (mint a platform token → provision
freely; flip `ENABLE_SSO_ONLY_LOGIN` off → re-open native login). This is why the
protection below matters more than any per-tenant guard.

## 2. Who can access it (the identity model)

- Super Admin is a **separate Devise scope** — `devise_for :super_admins, path:
  'super_admin'`, model `SuperAdmin < User` (STI on `users.type = 'SuperAdmin'`).
  Authenticating to it requires a **SuperAdmin credential**, which is a different
  thing from any tenant login.
- **Vendors and agents are never Super Admins.** Every tenant user is a plain `User`
  (`type` NULL). Provisioning mints users via the Platform API
  (`POST /platform/api/v1/users`), which creates ordinary users — **no provisioning
  path sets `type: 'SuperAdmin'`**. So a tenant can never escalate into the console.
  (Regression-worthy invariant: assert no tenant-provisioned user has `type =
  'SuperAdmin'`.)
- A tenant's SSO landing (`/platform/api/v1/users/:id/login`) logs a user into the
  **dashboard** scope only; it cannot produce a `super_admin` session.

## 3. How it is protected today

| Control | Status | Where |
| --- | --- | --- |
| Separate credential model (not a tenant login) | ✅ built-in | `SuperAdmin` STI + `authenticate_super_admin!` |
| Brute-force throttle on login | ✅ built-in | `config/initializers/rack_attack.rb` — `5/5min` per IP, `5/15min` per email on `POST /super_admin/sign_in` |
| No tenant path into the scope | ✅ by construction | provisioning only mints `User`s |
| SSO-only lockdown covers it | ❌ **no** — separate scope | `Custom::DeviseOverrides::SessionsController` documents this explicitly |
| MFA enforced on login | ❌ **no** — password only | `SuperAdmin::Devise::SessionsController#create` checks `valid_password?` only; it never verifies `otp_*`, even though the columns exist |
| Default seed credential in prod | ⚠️ **must be prevented** | `db/seeds.rb` seeds `john@acme.inc / Password1!` as a `SuperAdmin` — dev only |
| Network restriction on `/super_admin` | ⚠️ **deployment responsibility** | not enforced by the app |

So out of the box the console is reachable at a **public password form**
(`/super_admin/sign_in`) with throttling but **no MFA**. The password + network
posture is therefore the real protection — see §5.

## 4. Managing Super Admins (operator runbook)

**Access the console:** browse to `https://<chatwoot-host>/super_admin` and sign in
with a SuperAdmin credential (redirects to `/super_admin/sign_in` when unauthenticated).

### 4.1 First-boot bootstrap (recommended) — `fork:super_admin:bootstrap`

The fork ships an **idempotent bootstrap** so a fresh instance comes up with a real,
env-driven operator instead of the insecure dev seed. It is safe to run on every boot.

- Service: `custom/app/services/custom/super_admin_bootstrap.rb` (fork-owned).
- Task: `lib/tasks/fork/super_admin.rake` → `bundle exec rails fork:super_admin:bootstrap`.
- Tests: `spec/custom/services/super_admin_bootstrap_spec.rb`.

**Environment** (put in your secrets manager / Chatwoot `.env`):

| Var | Effect |
| --- | --- |
| `SUPER_ADMIN_EMAIL` | Operator login email (required to do anything). |
| `SUPER_ADMIN_PASSWORD` | Strong password. Chatwoot enforces upper+lower+digit+special; a weak value **fails loud** (never leaves the box operator-less). |
| `SUPER_ADMIN_NAME` | Display name (default `Platform Operator`). |
| `SUPER_ADMIN_ROTATE_PASSWORD=true` | Reset an existing operator's password (off by default, so reboots don't churn it). |
| `SUPER_ADMIN_REMOVE_DEFAULT_SEED=true` | Delete the `john@acme.inc` seed admin (never the configured operator). |
| `SUPER_ADMIN_DISABLE_SIGNUP=true` | Turn off public self-signup (`ENABLE_ACCOUNT_SIGNUP=false`). |

Behavior: creates the operator only when missing; leaves an existing password alone
unless `ROTATE`; only writes configs that changed. It intentionally does **not** flip
`ENABLE_SSO_ONLY_LOGIN` (a tenant-facing control with lockout risk — enable that
separately per `../../../meta-saas/docs/operations/chatwoot-access-lockdown.md`).

**Wire it into first boot.** In your deploy (`docker-compose*.yaml` / k8s), run it
after DB prepare and before the server starts — e.g. the rails service `command`:

```yaml
command:
  - sh
  - -c
  - >
    bundle exec rails db:chatwoot_prepare &&
    bundle exec rails fork:super_admin:bootstrap &&
    bundle exec rails server -b 0.0.0.0 -p 3000
```

(Editing your own deploy config, not upstream Ruby — stays merge-clean.) Or run it
one-shot after a deploy: `docker compose run --rm rails bundle exec rails fork:super_admin:bootstrap`.

### 4.2 Manual (console)

Once at least one Super Admin exists, use the console's **Users → New** screen and set
the type to Super Admin. Or, out-of-band on the host (never a seeded default):

```bash
docker exec chatwoot-rails-1 bundle exec rails runner '
  sa = SuperAdmin.new(
    name: "Ops <name>",
    email: "ops-<name>@yourcompany.com",
    password: ENV.fetch("NEW_SUPER_ADMIN_PASSWORD")  # strong, unique, from your secrets manager
  )
  sa.skip_confirmation!  # no email flow for the operator scope
  sa.save!
  puts "created SuperAdmin ##{sa.id} #{sa.email}"
'
```

**Rotate / revoke:**

```bash
# Reset a password:
docker exec chatwoot-rails-1 bundle exec rails runner '
  sa = SuperAdmin.find_by!(email: "ops-<name>@yourcompany.com")
  sa.password = ENV.fetch("NEW_SUPER_ADMIN_PASSWORD"); sa.save!'

# Remove access (demote or delete):
docker exec chatwoot-rails-1 bundle exec rails runner '
  SuperAdmin.find_by!(email: "ops-<name>@yourcompany.com").destroy!'
```

**Rotate the `PLATFORM_TOKEN`** (Platform App access token) from **Platform Apps** in
the console (or the Rails console) if it may be exposed — the control plane's
`CHATWOOT_PLATFORM_TOKEN` must be updated to match.

## 5. Hardening checklist (production)

The app-level controls above are necessary but **not sufficient** — close these at
deploy time:

1. **Remove the default seed credential.** Never run `db/seeds.rb` (or its
   `john@acme.inc / Password1!` Super Admin) in any non-dev environment. The
   bootstrap (§4.1) removes it for you when `SUPER_ADMIN_REMOVE_DEFAULT_SEED=true`.
   Verify no Super Admin exists except the ones you created:
   `SuperAdmin.pluck(:id, :email)`.
2. **Network-restrict `/super_admin` and `/monitoring/sidekiq`.** Put them behind a
   VPN / IP allowlist / reverse-proxy auth (mTLS or SSO proxy). The operator console
   should **not** be reachable from the public internet — this is the primary
   mitigation for the missing MFA and the public login form. Coordinate with
   `../../docs/operations/*` ingress hardening (meta-saas backlog 07).
3. **Strong, unique credentials + a secrets manager.** No shared or reused passwords;
   one Super Admin per operator so access is attributable.
4. **Keep the login throttle on** (`rack_attack`) and alert on repeated
   `super_admin/sign_in` 401s / throttle hits.
5. **HTTPS only**; `FRONTEND_URL` / `PUBLIC_API_URL` are real public HTTPS URLs.
6. **Treat installation-config and Platform-App changes as privileged.** Log and
   review them; a change to `ENABLE_SSO_ONLY_LOGIN`, `ENABLE_ACCOUNT_SIGNUP`, or a new
   Platform App is a security event.
7. **(Enhancement) Enforce MFA for the scope.** The `otp_*` columns exist on `users`
   but the fork's `SuperAdmin::Devise::SessionsController#create` does not check them.
   Until that path enforces OTP, rely on network restriction (item 2). If you add MFA,
   do it in the `custom/` overlay so it stays upstream-merge-safe.

## 6. Relationship to the rest of the platform

- Vendors never touch this — they land in their **own** Chatwoot account as
  `administrator` via the meta-saas SSO bounce. See
  [`../../docs/operations/chatwoot-access-lockdown.md`](../../../meta-saas/docs/operations/chatwoot-access-lockdown.md)
  (SSO-only login) and `CHATWOOT_ENGINE_INTEGRATION.md` §4.5/§4.6.
- Plan limits are set by the **control plane** via the Platform API (whose token is a
  Platform App managed here), not by hand in this console. See `ENTITLEMENTS.md` /
  `PROVISIONING.md`.
- Roles overview: `ROLES_AND_CONTROL.md` (Super Admin = the platform operator).

## 7. Verification / audit commands

```bash
# Who has Super Admin? (should be only your named operators — no john@acme.inc)
docker exec chatwoot-rails-1 bundle exec rails runner 'pp SuperAdmin.pluck(:id, :email)'

# No tenant-provisioned user is a Super Admin (expect []):
docker exec chatwoot-rails-1 bundle exec rails runner \
  'pp User.where(type: "SuperAdmin").where("email LIKE ?", "%@handoff.local").pluck(:email)'

# Is the console publicly reachable? (from OUTSIDE the allowlist this must NOT return 200)
curl -s -o /dev/null -w "%{http_code}\n" https://<chatwoot-host>/super_admin/sign_in
```
