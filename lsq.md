# LeadSquared CRM Integration (Backend)

## High-Level Flow
- Accounts enable the `leadsquared` app via `config/integration/apps.yml`; the app is gated by the `crm_integration` feature flag and exposes settings for API keys, activity toggles, and scores.
- Creating an `Integrations::Hook` (`app/models/integrations/hook.rb`) for this app stores credentials, marks the hook as `account`-scoped, and enqueues `Crm::SetupJob` to prepare LeadSquared-side prerequisites.
- `Crm::SetupJob` (`app/jobs/crm/setup_job.rb`) instantiates `Crm::Leadsquared::SetupService` to resolve the tenant-specific API endpoint/timezone and ensure required custom activity types exist. The job persists setup output back into the hook’s `settings` json.
- Runtime events (`contact.updated`, `conversation.created`, `conversation.resolved`) fan out through `HookListener` (`app/listeners/hook_listener.rb`) to `HookJob` (`app/jobs/hook_job.rb`), which serialises processing per hook with a Redis mutex and delegates to `Crm::Leadsquared::ProcessorService`.
- Processor services under `app/services/crm/leadsquared/` orchestrate LeadSquared API calls, map Chatwoot data into LeadSquared payloads, and store external IDs/activity metadata on contacts and conversations to retain linkage.

## Key Responsibilities by File
- `config/integration/apps.yml`: Declares the LeadSquared app, required credentials (`access_key`, `secret_key`), optional activity toggles, score defaults, and visibility of stored settings. The schema enforces the shape of hook `settings` coming from the UI.
- `app/models/integrations/hook.rb`: Persists integration hooks, enforces uniqueness per account, validates settings via the JSON schema above, checks the `crm_integration` feature flag, and enqueues CRM setup after creation. Stores a deterministic encrypted `access_token` and exposes `feature_allowed?`.
- `app/jobs/crm/setup_job.rb`: Background job that loads the hook, short-circuits disabled/missing hooks, and invokes the right CRM-specific setup service (currently only LeadSquared).
- `app/services/crm/leadsquared/setup_service.rb`: Calls LeadSquared’s `Authentication.svc/UserByAccessKey.Get` to derive tenant-specific API and app hosts, updates hook settings (`endpoint_url`, `app_url`, `timezone`), and ensures custom activity types for conversation start/transcript exist (creating them if absent) while persisting their numeric codes.
- `app/jobs/hook_job.rb`: Consumes domain events and routes them per integration. For LeadSquared it locks on `Redis::Alfred::CRM_PROCESS_MUTEX` (`lib/redis/redis_keys.rb`) to avoid creating duplicate leads during rapid event bursts, then passes processing to the CRM service.
- `app/services/crm/base_processor_service.rb`: Shared helpers for CRM processors—enforces interface (`handle_contact_created/updated`, `handle_conversation_created/resolved`), provides helpers for checking contact identifiability, reading/storing external IDs on contacts, and attaching metadata to conversations.
- `app/services/crm/leadsquared/processor_service.rb`: Main runtime handler. Wires API clients, honours the hook’s `enable_*` toggles, processes contacts (create/update leads) and conversations (post LeadSquared activities), and records resulting IDs/metadata back to Chatwoot models. Uses `ChatwootExceptionTracker` for surfaced errors.
- `app/services/crm/leadsquared/lead_finder_service.rb`: Retrieves an existing lead ID from stored contact metadata, searches LeadSquared by email or phone when absent, and creates a new lead as a last resort.
- `app/services/crm/leadsquared/api/base_client.rb`: Thin HTTParty wrapper that signs requests with LeadSquared access/secret keys, centralises response parsing, and raises `ApiError` on non-success or malformed responses.
- `app/services/crm/leadsquared/api/lead_client.rb`: Exposes search/update/create operations for leads, including `create_or_update_lead` (default LeadSquared behaviour) and an explicit `update_lead` used when the Chatwoot contact already stores the external ID.
- `app/services/crm/leadsquared/api/activity_client.rb`: Manages posting activities against leads and creating/fetching activity types.
- `app/services/crm/leadsquared/mappers/contact_mapper.rb`: Normalises Chatwoot contact fields to LeadSquared attribute keys, reformats phone numbers to `+<country>-<national>` form, and injects brand/source info.
- `app/services/crm/leadsquared/mappers/conversation_mapper.rb`: Builds human-readable activity notes for conversation creation and transcript events, trimming content to LeadSquared limits and linking back to the Chatwoot conversation URL.

## Lifecycle by Use Case

### Hook Creation & Setup
1. Admin enables the integration, supplying at least `access_key`/`secret_key`.
2. `Integrations::Hook` persists the hook (`hook_type: account`) and enqueues `Crm::SetupJob`.
3. `SetupService` resolves tenant metadata, resets clients to the tenant-specific base URL, and ensures two activity types:
   - `<Brand> Conversation Started`
   - `<Brand> Conversation Transcript`
   Their numeric codes and resolved URLs/timezone are stored back into `hook.settings`.
4. Subsequent API calls use the tenant-specific endpoint and the hook’s stored codes/timezone.

### Contact Sync (`contact.updated`)
- Trigger: `HookListener#contact_updated` dispatches when a Chatwoot contact changes.
- `HookJob` locks per hook, instantiates `Crm::Leadsquared::ProcessorService`, and calls `handle_contact`.
- Processor reloads the latest contact, skips if lacking email/phone/social profile, and retrieves any stored LeadSquared ID.
- With an ID it calls `LeadClient#update_lead`; otherwise it calls `LeadClient#create_or_update_lead` and persists the returned `ProspectID` into `contact.additional_attributes['external']['leadsquared_id']`.
- Any API/runtime error is captured via `ChatwootExceptionTracker` and logged; failures do not retry via the mutex job by default.

### Conversation Created (`conversation.created`)
- Trigger: `HookListener#conversation_created`.
- `HookJob` locks and delegates to `handle_conversation_created`.
- Processor exits early if the hook has `enable_conversation_activity` disabled.
- Uses `LeadFinderService` to fetch or create the lead ID tied to the conversation’s contact (persisting it if newly discovered).
- Builds the activity note via `ConversationMapper.map_conversation_activity`, fetches the configured `conversation_activity_code`, and posts the activity with `ActivityClient#post_activity`.
- Stores the resulting activity ID under `conversation.additional_attributes['leadsquared']['created_activity_id']` for traceability.

### Conversation Resolved (`conversation.resolved`)
- Trigger: `HookListener#conversation_resolved` when status transitions to `resolved`.
- `HookJob` locks and calls `handle_conversation_resolved`.
- Processor requires `enable_transcript_activity` to be true and the conversation status to still be `resolved`.
- Builds a transcript note (reverse-chronological, capped at 1,800 chars, including attachments) via `ConversationMapper.map_transcript_activity`.
- Posts the transcript activity using `transcript_activity_code` and records the returned ID as `conversation.additional_attributes['leadsquared']['transcript_activity_id']`.

## Stored Metadata & Settings
- Hook settings persist credentials, resolved endpoint/app URLs, timezone, activity toggles, scores, and the created activity type codes. These values feed processor behaviour and the frontend’s “visible properties” list.
- Contacts store `additional_attributes['external']['leadsquared_id']` once a LeadSquared prospect exists.
- Conversations store a nested `additional_attributes['leadsquared']` hash with any activity IDs created.

## Error Handling & Concurrency
- All API wrappers raise `ApiError` on non-success; callers rescue to log and forward to `ChatwootExceptionTracker`.
- `HookJob` inherits from `MutexApplicationJob`; coupled with the per-hook Redis mutex it prevents concurrent processing of contact/conversation events that would otherwise create duplicate leads.
- Unsupported events or disabled hooks short-circuit in `HookListener`/`HookJob`, avoiding unnecessary API calls.

## Extensibility Notes
- The LeadSquared implementation follows the `Crm::BaseProcessorService` contract, simplifying future CRM additions.
- Setup work is encapsulated so additional CRMs can hook into `Crm::SetupJob#create_setup_service`.
- Feature flag (`crm_integration`) and hook JSON schema guardrails ensure enterprise-only exposure and predictable payloads.
