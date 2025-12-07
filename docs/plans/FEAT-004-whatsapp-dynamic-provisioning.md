# Plan: Dynamic WhatsApp Instance Provisioning via Admin API

## Overview

Add the ability to dynamically provision new WhatsApp Web instances through the Go WhatsApp Multidevice Admin API, in addition to the existing flow of connecting to pre-existing instances.

## Design Decisions

| Decision | Choice |
|----------|--------|
| Admin API credentials | Per-account (stored in account settings) |
| Port allocation | Auto-assign from configurable range |
| Instance lifecycle | Delete instance when inbox is deleted |
| UI flow | Toggle within WhatsApp Web form |

---

## Implementation Phases

### Phase 1: Backend Services (New Files)

**1. Admin API Client**
`app/services/whatsapp/admin_api_client.rb`
```ruby
class Whatsapp::AdminApiClient
  def initialize(account)
  def create_instance(port:, webhook:, webhook_secret:, basic_auth: nil)
  def list_instances
  def get_instance(port)
  def update_instance(port, config)
  def delete_instance(port)
  def health_check
end
```

**2. Instance Provisioning Service**
`app/services/whatsapp/instance_provisioning_service.rb`
```ruby
class Whatsapp::InstanceProvisioningService
  def provision(account:, phone_number:, webhook_secret:)
    # 1. Find available port from account's configured range
    # 2. Build Chatwoot webhook URL
    # 3. Create instance via Admin API
    # 4. Poll until RUNNING state (30s timeout)
    # 5. Return {gateway_url, port, basic_auth}
  end
end
```

**3. Instance Teardown Service**
`app/services/whatsapp/instance_teardown_service.rb`
```ruby
class Whatsapp::InstanceTeardownService
  def perform(channel)
    # Only if provider_config['provisioned'] == true
    # Call Admin API delete_instance(port)
  end
end
```

### Phase 2: Model Changes

**Account Model** (`app/models/account.rb`)
- Add to settings schema: `whatsapp_admin_api_base_url`, `whatsapp_admin_api_token`, `whatsapp_admin_port_range_start`, `whatsapp_admin_port_range_end`
- Add `store_accessor` for these fields
- Add helper: `whatsapp_admin_api_configured?`

**Channel::Whatsapp Model** (`app/models/channel/whatsapp.rb`)
- Add `before_destroy :teardown_provisioned_instance`
- New provider_config fields (documented, no migration needed):
  - `provisioned: true/false`
  - `instance_port: 3001`

### Phase 3: Controller & Routes

**New Controller** (`app/controllers/api/v1/accounts/whatsapp_web/gateway_controller.rb`)
Add endpoints:
- `POST provision_instance` - Create new instance
- `GET admin_api_status` - Check if Admin API configured & healthy
- `GET available_instances` - List instances from Admin API

**Routes** (`config/routes.rb`)
```ruby
namespace :whatsapp_web do
  resources :gateway, only: [], controller: 'gateway' do
    collection do
      post :provision_instance
      get :admin_api_status
      get :available_instances
    end
  end
end
```

**Accounts Controller** (`app/controllers/api/v1/accounts_controller.rb`)
- Permit new settings params

### Phase 4: Frontend - Account Settings

**New Component** (`app/javascript/dashboard/routes/dashboard/settings/account/components/WhatsappAdminApi.vue`)
- Admin API URL input
- Admin Token input (password field)
- Port range inputs (start/end)
- Test connection button
- Save settings

**Account Settings Index** (`app/javascript/dashboard/routes/dashboard/settings/account/Index.vue`)
- Import and add WhatsappAdminApi component

### Phase 5: Frontend - Inbox Creation

**WhatsappWebForm.vue** (`app/javascript/dashboard/routes/dashboard/settings/inbox/channels/whatsapp/WhatsappWebForm.vue`)
- Add `connectionMode` toggle: `'existing'` | `'create_new'`
- Show toggle only if Admin API is configured for account
- **Create New mode**: Hide gateway URL fields, show only phone + webhook secret
- **Existing mode**: Current form (no changes)
- Update submit handler for provisioning flow

**API Client** (New: `app/javascript/dashboard/api/whatsappAdminApi.js`)
```javascript
checkAdminApiStatus()
provisionInstance(phoneNumber, webhookSecret)
```

**Vuex Store** (`app/javascript/dashboard/store/modules/accounts.js`)
- Add `updateWhatsappAdminSettings` action
- Add `checkWhatsappAdminApiStatus` action

### Phase 6: i18n Translations

**inboxMgmt.json** - Add under `WHATSAPP_WEB`:
- `PROVISIONING_MODE.LABEL/CREATE_NEW/CONNECT_EXISTING`
- `PROVISIONING.IN_PROGRESS/SUCCESS/ERROR/NO_PORTS_AVAILABLE`

**settings.json** - Add `WHATSAPP_ADMIN_API` section

---

## Critical Files

| File | Changes |
|------|---------|
| `app/models/account.rb` | Add settings schema + accessors |
| `app/models/channel/whatsapp.rb` | Add teardown callback |
| `app/services/whatsapp/admin_api_client.rb` | NEW - HTTP client |
| `app/services/whatsapp/instance_provisioning_service.rb` | NEW - Orchestration |
| `app/services/whatsapp/instance_teardown_service.rb` | NEW - Cleanup |
| `app/controllers/api/v1/accounts/whatsapp_web/gateway_controller.rb` | Add endpoints |
| `config/routes.rb` | Add routes |
| `WhatsappWebForm.vue` | Add provisioning toggle |
| `app/javascript/dashboard/api/whatsappAdminApi.js` | NEW - API client |

---

## Provisioning Flow Sequence

```
User → Frontend → Backend → Admin API
  |
  1. Select "Create New Instance"
  2. Enter phone number + webhook secret
  3. Submit
     |
     → POST /provision_instance
        |
        → GET /admin/instances (find available port)
        → POST /admin/instances (create with webhook)
        → Poll GET /admin/instances/{port} until RUNNING
        |
     ← Return {gateway_url, port, credentials}
     |
  4. POST /inboxes (create channel with provisioned=true)
  5. Redirect to agents page
```

---

## Error Handling

| Error | Response |
|-------|----------|
| Admin API not configured | 400 - Guide user to account settings |
| No ports available | 503 - All ports in range in use |
| Instance creation failed | 500 - Log + cleanup partial instance |
| Timeout waiting for RUNNING | 504 - 30s timeout exceeded |
| Admin API unreachable | 503 - Service unavailable |

---

## Implementation Order

1. Backend services (AdminApiClient, ProvisioningService, TeardownService)
2. Account model changes + controller params
3. Gateway controller endpoints + routes
4. Frontend account settings component
5. Frontend WhatsappWebForm provisioning toggle
6. i18n translations
7. Manual testing
