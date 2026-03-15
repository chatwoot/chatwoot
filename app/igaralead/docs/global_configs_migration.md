# Nexus – Current Global Configurations (for Hub migration)

This document lists all current Nexus (Chatwoot fork) settings and configurations
that may need to be migrated to or replaced by the IgaraHub central platform.

## 1. Account-Level Settings (JSONB `settings` column)

| Key | Type | Description |
|-----|------|-------------|
| `auto_resolve_after` | integer (10–1,439,856) | Minutes before auto-resolving conversations |
| `auto_resolve_message` | string | Message sent when auto-resolving |
| `auto_resolve_ignore_waiting` | boolean | Skip conversations in waiting state |
| `auto_resolve_label` | string | Label to apply on auto-resolve |
| `audio_transcriptions` | boolean | Enable audio transcription |
| `captain_models` | object | AI model selection per feature (editor, assistant, copilot, etc.) |
| `captain_features` | object | Feature flags per Captain AI capability |
| `keep_pending_on_bot_failure` | boolean | Keep conversation pending if bot fails |
| `captain_disable_auto_resolve` | boolean | Disable Captain auto-resolve |
| `conversation_required_attributes` | array (enterprise) | Required attributes before resolving |

### Hub Migration Strategy
- These are per-account operational settings — keep locally for Nexus
- Hub provides overridable **defaults** per organization via `nexus_settings` in org config
- Nexus merges Hub defaults with local account settings (local takes precedence)

## 2. Installation Config (Global/System Settings)

### Branding (candidates for Hub override)
| Key | Default | Notes |
|-----|---------|-------|
| `INSTALLATION_NAME` | "Chatwoot" | **Replace with Hub org name or "IgaraLead"** |
| `LOGO`, `LOGO_DARK`, `LOGO_THUMBNAIL` | Chatwoot assets | **Replace with IgaraLead assets** |
| `BRAND_URL`, `WIDGET_BRAND_URL` | chatwoot.com | **Replace with IgaraLead URLs** |
| `BRAND_NAME` | "Chatwoot" | **Replace with "IgaraLead"** |
| `TERMS_URL`, `PRIVACY_URL` | chatwoot.com | **Replace with IgaraLead URLs** |

### Account/Signup (may be Hub-controlled)
| Key | Default | Notes |
|-----|---------|-------|
| `ENABLE_ACCOUNT_SIGNUP` | false | **Disabled; Hub controls onboarding** |
| `CREATE_NEW_ACCOUNT_FROM_DASHBOARD` | false | **Disabled; Hub creates accounts** |
| `MAXIMUM_FILE_UPLOAD_SIZE` | 40 MB | Can be Hub-configured per org |

### Channel Credentials (keep as env/installation config)
| Key | Notes |
|-----|-------|
| `FB_APP_ID`, `FB_APP_SECRET`, `FB_VERIFY_TOKEN` | Facebook integration |
| `WHATSAPP_APP_ID`, `WHATSAPP_APP_SECRET` | WhatsApp Cloud API |
| `TIKTOK_APP_ID`, `TIKTOK_APP_SECRET` | TikTok |
| `AZURE_APP_ID`, `AZURE_APP_SECRET` | Microsoft |
| `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth |
| `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` | Slack |

These remain as installation-level env vars — not Hub-managed.

### AI/LLM (candidate for Hub tier control)
| Key | Notes |
|-----|-------|
| `CAPTAIN_OPEN_AI_API_KEY` | Shared API key |
| `CAPTAIN_OPEN_AI_MODEL` | Default model |
| `CAPTAIN_OPEN_AI_ENDPOINT` | API endpoint |
| `CAPTAIN_CLOUD_PLAN_LIMITS` | **Replace with Hub subscription limits** |

## 3. Feature Flags (per-account bit flags)

### Channel Flags
- `channel_email`, `channel_facebook`, `channel_website`, `channel_instagram`, `channel_tiktok`
- **Hub controls which channels are available per subscription**

### Premium/Gated Features
- `audit_logs`, `sla`, `saml`, `custom_roles`, `advanced_assignment`
- `captain_integration`, `captain_integration_v2`, `disable_branding`
- `companies` (CRM v2)
- **Hub subscription determines which premium features are enabled**

### Always-On Features
- `agent_management`, `team_management`, `inbox_management`
- `labels`, `macros`, `automations`, `canned_responses`
- `help_center`, `reports`, `integrations`, `crm`
- These remain enabled for all accounts.

## 4. Usage Limits (JSONB `limits` column)

| Key | Source | Notes |
|-----|--------|-------|
| `agents` | max_limit (100k) | **Replace with Hub subscription `nexus_users` allocation** |
| `inboxes` | max_limit (100k) | **Replace with Hub subscription `nexus_channels` allocation** |
| `captain_documents` | enterprise plan | **Replace with Hub limits** |
| `captain_responses` | enterprise plan | **Replace with Hub limits** |
| `emails` | config | Email sending limits |

## 5. Migration Plan

### Phase 1: Hub Settings Override (current implementation)
- `Igaralead::HubSettingsService` fetches org settings from Hub
- Returns `nexus_user_limit`, `nexus_channel_limit`, `nexus_features`
- Nexus applies these as enforcement boundaries

### Phase 2: Remove Local Defaults (future)
- Branding configs → sourced from Hub org config
- Account signup → fully disabled, Hub-managed
- Feature flags → gated by Hub subscription tier
- Usage limits → enforced from Hub subscription allocations

### Phase 3: Configuration Dashboard (future)
- Super-admin in Hub can set per-org Nexus settings
- These are pushed to Nexus or pulled on demand via API
- Local `InstallationConfig` table becomes read-only cache
