# Internal Tasks + Audio / ActionCable — review brief (PaluHub fork)

**Audience:** another AI or reviewer auditing this PR.  
**Branch:** `feat/internal-tasks`  
**PR:** https://github.com/pabloluna3596afk/chatwoot/pull/3  
**Base:** `develop`  
**Commits (feature core):**
- `42b82557d` — `feat(tasks): add internal tasks inbox with kanban and realtime updates`
- `a6412e00a` — `fix(tasks): improve card separation, beta badge, audio init and presence`

Also on this branch (pre-existing vs remote `develop`): WhatsApp interactive `action` hash fix, contacts UI tweaks, AGENTS Docker notes.

---

## 1. Product: Internal Tasks

Account-level work queue linked to conversations (not Chatwoot “Inbox” notifications).

### UX layout (mirrors Conversations)

| Area | Behavior |
|------|----------|
| Left | Task list (tabs Mine / Unclaimed / All; status + team filters) |
| Center when **no** task selected (`/app/accounts/:id/tasks`) | Kanban summary |
| Center when task selected | Task detail (overview, activity/notes, linked conversation tab) |
| Conversation sidebar | Accordion “Internal Tasks” + create form |
| Message context menu | Create task / start private note from message |

### Card fields (list + kanban)

- Title  
- Contact · conversation `#display_id`  
- Status (+ priority only if not `normal`)  
- Assignee (agent, else team)  
- Due date if set  
- Created at (`dynamicTime`)

### Beta

- Sidebar item **Tasks** shows `GENERAL.BETA` chip  
- Same chip on Task list header and Kanban header  

### Realtime

- ActionCable events for task create/update (see `lib/events/types.rb`, `action_cable_listener.rb`)  
- Store: `app/javascript/dashboard/store/modules/internalTasks.js`  
- Sidebar badge = **my open tasks** count (`getMyOpenTaskCount`), not unread  

### Backend surface

| Piece | Path |
|-------|------|
| Models | `app/models/internal_task.rb`, `internal_task_event.rb`, `task_template.rb` |
| API | `app/controllers/api/v1/accounts/internal_tasks_controller.rb`, `…/conversations/internal_tasks_controller.rb`, `task_templates_controller.rb`, timeline |
| Services | `app/services/internal_tasks/*`, `task_templates/default_seeder.rb` |
| Migrations | `db/migrate/2026070912*` |
| Routes | `config/routes.rb` (account-scoped) |
| UI | `app/javascript/dashboard/components-next/InternalTasks/*` |
| Routes FE | `app/javascript/dashboard/routes/dashboard/tasks/` |
| i18n | `en/internalTasks.json`, `es/internalTasks.json` |

### Deploy notes

- Run migrations after merge/redeploy.  
- Optional seed templates: `lib/tasks/internal_tasks.rake`.  
- Vue assets are **baked in Docker image** for this fork → `up -d --build` (not restart-only) for FE changes.

---

## 2. Audio alerts (dashboard ding)

**Not** browser `Notification` / push sound. In-app `HTMLAudioElement` via:

`app/javascript/dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper.js`

Triggered on ActionCable `message.created` (`dashboard/helper/actionCable.js`).

### Bug fixed

Constructor set tone to `ding`; `set()` only called `intializeAudio()` when tone **changed**. Default path left `audio === null` → silent failures.  

**Fix:** initialize when `audio` is null **or** tone changes; null-guard in `playAudioAlert`; permission flag stored on `audioConfig`.

### Pending (bot) conversations

Previously **all** pending chats skipped alerts (common with Panel AI bots).  

**Fix:** if conversation is pending, still alert when `message_type === INCOMING` (contact). Other pending traffic stays quiet.

### Still by design (reviewers must know)

| Setting / filter | Effect |
|------------------|--------|
| Profile `enable_audio_alerts` default `none` | No sound until agent enables Assigned / Unassigned / etc. |
| `always_play_audio_alert` default false | Sounds only when tab/window considered inactive |
| Viewing that conversation | No sound for that chat |
| Own messages | Skipped |
| Browser autoplay | May need a user gesture; toast once on `NotAllowedError` |

Ops note also in `AGENTS.md` → section **PaluHub — audio alerts & ActionCable (ops)**.

---

## 3. ActionCable / “tunnel drops” in background

Chatwoot does **not** disconnect cable on blur. Symptoms come from:

1. `@rails/actioncable` stale threshold (~6s) + background timer throttling → reopen loop (~5–15s feel).  
2. Presence TTL shorter than background pause → agent looks offline.  
3. Proxy idle (~60–100s Cloudflare) if heartbeats stop while tab frozen.

### Code changes

| Change | File |
|--------|------|
| Presence client interval **20s → 60s** | `app/javascript/shared/helpers/BaseActionCableConnector.js` |
| On `visibilitychange` → visible: `reopen()` if closed, presence ping, reconnect check | same |
| Server `PRESENCE_DURATION` default **20 → 90** | `lib/online_status_tracker.rb` |
| Documented in env examples | `.env.example`, `.env.staging.example`, `.env.production.project.example` (`PRESENCE_DURATION=90`) |

Reconnect data sync still via `ReconnectService` (unchanged contract).

### Infra checklist (no code)

- Same-origin `wss://…/cable`  
- Traefik/Cloudflare WS idle ≥ 60–120s, WebSockets ON  
- Cut ~100s → proxy; cut ~5–15s → client stale/tab freeze  

---

## 4. How to test (reviewer)

1. **Tasks UI:** `/app/accounts/1/tasks` — list separation, kanban cards, Beta chips, fields above; open task → detail; create from conversation sidebar / message menu.  
2. **Audio:** Profile → enable `assigned+unassigned` (or similar), leave tone `ding`, hard refresh; message in another chat / pending contact message should ding when tab inactive (or with “always play” on).  
3. **Cable:** leave tab background 30–60s, return — reconnect + messages catch up; presence not instantly offline.  
4. **Migrations:** fresh DB or `db:migrate` on deploy.

---

## 5. Out of scope / known follow-ups

- Kanban drag-and-drop  
- Changing default `enable_audio_alerts` away from `none`  
- Patching ActionCable `staleThreshold` in `node_modules`  
- Instagram OAuth POST token fix (still pending elsewhere)  

### Bugs encontrados en revisión posterior (no en este PR)

Después de mergear, en sesión de revisión (2026-07-11) se encontraron 5 bugs
adicionales al scope de este PR. Ver [`docs/BUGS.md`](BUGS.md) para el detalle.

Resumen:

| ID | Archivo | Fix |
|----|---------|-----|
| `TASK-001` | `app/services/conversations/timeline_builder.rb` | Notas privadas ya no se filtran a todos (admin/autor/equipo sí ven; resto no) |
| `TASK-002` | `routes/dashboard/tasks/TaskView.vue` | `clearSelectedState` ahora existe en módulo `internalTasks` |
| `TASK-003` | `app/services/internal_tasks/claim_service.rb` | Race condition en `claim` ahora devuelve 409 con JSON semántico |
| `TASK-004` | `app/models/internal_task.rb` | `depends_on_task_id` validado a la misma cuenta |
| `TASK-005` | `TaskDetail.vue` | Import muerto `currentChat` removido |

Estos fixes viven en commits posteriores al cierre de este PR.
**Si los mergeas al PR #3, actualiza este doc.**  

### UX follow-ups (sesión reply/templates)

| Item | Archivos | Qué hace |
|------|----------|----------|
| Reply preview en nota privada | `ReplyBox.vue` | `shouldShowReplyToMessage` muestra `ReplyToMessage` también en modo nota (sin exigir feature de canal) |
| Botones de plantilla WA en bubble | `WhatsAppTemplateParser.vue`, `templateHelper.js`, `bubbles/Text/Index.vue` | Al enviar, snapshot `content_attributes.template_buttons`; el bubble del agente lista labels/URL/phone |

---

## 6. Related ops docs

| Doc | Role |
|-----|------|
| [`AGENTS.md`](../AGENTS.md) | Fork workflow + short audio/cable ops section |
| [`docs/LOCAL_DEV.md`](LOCAL_DEV.md) | Local Docker |
| [`docs/DOKPLOY_ENV.md`](DOKPLOY_ENV.md) | Env / deploy |
| This file | Full change brief for AI/human review of this PR |
