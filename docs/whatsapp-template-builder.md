

Fetched https://github.com/chatwoot/chatwoot/pull/12231

Searched codebase for "WhatsApp template builder create campaign form inbox", 16 results

Now I have a full picture of the PR and the current codebase. Here's the brainstorm:

---

## WhatsApp Template Builder — Implementation Breakdown

### What PR #12231 Actually Built

The PR (still **Open**, currently targeting v4.12.0 — milestone-slipped from v4.9 → v4.10 → v4.11 → v4.12) is **feature-complete but stuck in review**. It built:

- `MessageTemplate` model with a `message_templates` DB table (JSONB `content`, enums for `status` and `category`)
- `MessageTemplatesController` — CRUD REST endpoints
- `Whatsapp::TemplateCreationService` — submits to Meta Graph API
- `Whatsapp::FacebookUploadService` — uploads header media to Meta before creation
- `Whatsapp::TemplateSyncService` — syncs approved templates back to the DB
- `TemplateBuilderPage.vue` — modular header/body/footer/buttons sections with live preview
- `messageTemplates.js` — Vuex store + API client
- Feature-flagged behind `template_builder`

**Why it wasn't ported here**: This fork was cut from upstream before those commits landed, and the PR has never been merged.

---

### Current State in AirysChat

Today, templates can only be **created directly in Meta Business Manager**. They land in Chatwoot via `Whatsapp::SyncTemplatesJob` which syncs them into the `message_templates` JSONB column on `Channel::Whatsapp`. The campaign form reads from `inboxes/getFilteredWhatsAppTemplates`, and CSAT has its own `Whatsapp::CsatTemplateService` that creates one specific template type. There is **zero UI for creating arbitrary templates**.

---

### Proposed Implementation Plan

#### Backend (6 pieces)

**1. Migration + Model**
```
message_templates
  id, account_id, inbox_id, created_by_id
  name (string, snake_case enforced)
  language (string, default 'en')
  category (enum: marketing/utility/authentication)
  status (enum: draft/pending/approved/rejected/paused)
  content (jsonb) → { components: [...] }  ← Meta's exact format
  platform_template_id (the Meta-assigned ID after approval)
  last_synced_at, metadata (jsonb)
  UNIQUE INDEX on (account_id, name, language, channel_type)
```

**2. `Whatsapp::TemplateCreationService`**
Builds and POSTs to `POST /<version>/<waba_id>/message_templates` on the Meta Graph API. The existing `Whatsapp::CsatTemplateService` already does this for CSAT templates — we extract and generalize that logic.

**3. `Whatsapp::FacebookUploadService`**
For IMAGE/VIDEO/DOCUMENT headers: upload the blob (from ActiveStorage, already uploaded via `/api/v1/accounts/:id/upload`) to Meta's Sessions API to get a `media_handle`, then include it in the component example. The PR's approach is sound here.

**4. `Whatsapp::TemplateSyncService`**
After creation, Meta puts the template in `PENDING` status. This service polls Meta for the status and upserts into `message_templates`. It also migrates legacy JSONB templates from `Channel::Whatsapp#message_templates` into the new table — this eliminates the need for the lazy migration hack the PR proposed.

**5. `MessageTemplatesController`**
`GET /accounts/:id/message_templates` — list, filterable by `inbox_id` and `status`  
`POST /accounts/:id/message_templates` — create + submit to Meta  
`GET /accounts/:id/message_templates/:id` — show  
`DELETE /accounts/:id/message_templates/:id` — delete from Meta + local  

**6. Policy + feature flag**
`MessageTemplatePolicy` — admin-only for create/delete, agents can list/show.  
Feature flag: `whatsapp_template_builder` (same pattern as `whatsapp_campaign`).

---

#### Frontend (4 pieces)

**1. Store + API client**
`store/modules/messageTemplates.js` — list, create, delete, set current.  
`api/messageTemplates.js` — wraps the controller endpoints.  
The store also invalidates `inboxes/getFilteredWhatsAppTemplates` after a successful create+approval so templates immediately appear in the campaign form.

**2. Route placement**
Debated in the PR: per-inbox vs account-level. Recommended approach: **Settings → Templates** (sidebar link), account-level list with an inbox filter dropdown. This is friendlier than burying it 3 levels deep in inbox settings. The list page shows name, category, language, inbox, status badge (PENDING/APPROVED/REJECTED), and a "Create template" button.

**3. `TemplateBuilderPage.vue`** — the main work
Live split-pane layout: builder on the left, WhatsApp phone mock on the right.

Sections (each collapsible, in submission order):
| Section | Options |
|---|---|
| **Basic** | Name (auto-converts to snake_case), Category, Language, Inbox selector |
| **Header** | None / Text (with `{{1}}` variable) / Image / Video / Document |
| **Body** | Textarea with markdown + `{{n}}` variable insertion helper, char count |
| **Footer** | Optional short text |
| **Buttons** | Quick Reply (up to 3) / Call to Action: Phone, URL with optional variable / Auth OTP button |

Variable sample values are required before submission (Meta rejects without them).

**4. Integration touchpoints**
- **Campaign form** → "Create new template" link opens the builder in a side panel
- **CSAT settings page** → "Create CSAT template" button already exists — wire it through the template builder instead of the separate CSAT-specific flow
- **Template status badge** shown inline with a "refresh status" button that re-polls Meta

---

### Key Improvements Over the PR

| PR #12231 issue | Our approach |
|---|---|
| Lazy migration with overridden `message_templates` method | Clean one-shot migration job: read JSONB, insert into new table, clear JSONB |
| No connection to campaign form | After approval, auto-syncs to campaign template dropdown |
| Separate CSAT template flow | Unify: CSAT just creates a `MessageTemplate` with `category: :utility` |
| No status polling | `Whatsapp::TemplateSyncJob` — polls on a schedule + manual refresh button |
| Media cleanup left open | Purge orphan ActiveStorage blobs that were never submitted (30-min TTL job) |

---

### Effort Estimate

| Area | Effort |
|---|---|
| Migration + model + policy | 0.5d |
| `TemplateCreationService` + `FacebookUploadService` | 1d |
| `TemplateSyncService` + background job | 1d |
| Controller + routes + feature flag | 0.5d |
| Template list page | 0.5d |
| **Template builder UI + preview** | 3–4d |
| Integration (campaigns, CSAT) | 1d |
| **Total** | **~7–8 days** |

---

### Recommended Starting Point

Port the PR's backend services first (they are well-structured and already reviewed by Chatwoot core team), then build the frontend fresh using the `components-next/` design system (the PR used older components). The builder UI is the hard part — the phone preview mock and variable substitution logic are the real investment.

Want me to start implementing any specific piece?