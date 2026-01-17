# CommMate User Roles & Permissions

Complete guide for managing user roles and permissions in CommMate.

**Last Updated**: January 17, 2026  
**Version**: CommMate v4.9.2+

---

## Overview

CommMate uses a **per-user permission model** where:
- Users have a **base role** (Administrator or Agent)
- Agents can have additional **access permissions** assigned individually

This replaces the previous Custom Roles feature and ensures full license compliance with Chatwoot's open source license.

---

## Base Roles

| Role | Permissions | Use Case |
|------|-------------|----------|
| **Administrator** | Full access to everything | Account owners, IT admins |
| **Agent** | Handle conversations, basic access | Customer support agents |

---

## Available Permissions

### Conversation Permissions

All agents can see conversations **assigned to them** by default. Additional permissions extend what they can see:

| Permission | Description | What It Adds |
|------------|-------------|--------------|
| (Base Agent) | Default access | Only conversations assigned to them |
| `conversation_participating_manage` | See participating conversations | + Conversations where they are a participant |
| `conversation_unassigned_manage` | See unassigned conversations | + Unassigned conversations |
| `conversation_manage` | Manage ALL conversations | Full access to all conversations |

**Note:** Permissions stack - an agent with both `conversation_participating_manage` and `conversation_unassigned_manage` sees: assigned + participating + unassigned conversations.

### Feature Permissions

| Permission | Description |
|------------|-------------|
| `contact_manage` | Manage contacts (edit, merge, delete) |
| `report_manage` | Access analytics and reports |
| `knowledge_base_manage` | Manage help center articles |
| `campaign_manage` | Manage marketing campaigns |
| `templates_manage` | Manage WhatsApp message templates |

### Settings Permissions

| Permission | Description |
|------------|-------------|
| `settings_account_manage` | General account settings |
| `settings_agents_manage` | Manage agents |
| `settings_teams_manage` | Manage teams |
| `settings_inboxes_manage` | Manage inboxes |
| `settings_labels_manage` | Manage labels |
| `settings_custom_attributes_manage` | Manage custom attributes |
| `settings_automation_manage` | Manage automation rules |
| `settings_agent_bots_manage` | Manage agent bots |
| `settings_integrations_manage` | Manage integrations |
| `settings_macros_manage` | Manage macros |

---

## Assigning Permissions

### In Chatwoot UI

1. Go to **Settings → Agents**
2. Click **Edit** on an agent
3. Select **Role** as "Agent"
4. Check the desired **Additional Permissions**
5. Click **Save**

Administrators automatically have all permissions - the permissions checkboxes only appear for agents.

### Via Database (for bulk updates)

```bash
# Add campaign_manage permission to a user
UPDATE account_users 
SET access_permissions = array_append(access_permissions, 'campaign_manage')
WHERE user_id = USER_ID AND account_id = ACCOUNT_ID;

# View users with their permissions
SELECT u.name, u.email, au.role, au.access_permissions 
FROM users u 
JOIN account_users au ON u.id = au.user_id 
WHERE au.account_id = 1;
```

---

## How Permissions Work

### Data Model

Permissions are stored in `account_users.access_permissions` as a PostgreSQL text array:

```ruby
# app/models/account_user.rb
AVAILABLE_PERMISSIONS = %w[
  conversation_manage
  conversation_unassigned_manage
  conversation_participating_manage
  contact_manage
  report_manage
  knowledge_base_manage
  campaign_manage
  templates_manage
  settings_macros_manage
  settings_account_manage
  settings_agents_manage
  settings_teams_manage
  settings_inboxes_manage
  settings_labels_manage
  settings_custom_attributes_manage
  settings_automation_manage
  settings_agent_bots_manage
  settings_integrations_manage
].freeze

def permissions
  # Returns base role permissions + access_permissions
  base_permissions = administrator? ? ['administrator'] : ['agent']
  base_permissions + (access_permissions || [])
end
```

### Permission Flow

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  AccountUser    │────▶│   permissions    │────▶│  Frontend/API   │
│ access_perms[]  │     │   method         │     │   checks        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                                                  │
        │                                                  ▼
        │                                         ┌─────────────────┐
        │                                         │  Route Access   │
        │                                         │  Menu Display   │
        │                                         │  Data Filtering │
        └────────────────────────────────────────▶│  Policy Checks  │
                                                  └─────────────────┘
```

---

## Implementing Policies

### Backend Policy Enforcement

#### 1. Creating a Policy Class

```ruby
# app/policies/your_feature_policy.rb
class YourFeaturePolicy < ApplicationPolicy
  def index?
    administrator_or_has_permission?('your_feature_manage')
  end

  def create?
    administrator_or_has_permission?('your_feature_manage')
  end

  def update?
    administrator_or_has_permission?('your_feature_manage')
  end

  def destroy?
    administrator? # Only admins can delete
  end

  private

  def administrator_or_has_permission?(permission)
    @account_user.administrator? || 
    @account_user.permissions.include?(permission)
  end

  def administrator?
    @account_user.administrator?
  end
end
```

#### 2. Using Policies in Controllers

```ruby
# app/controllers/api/v1/accounts/your_feature_controller.rb
class Api::V1::Accounts::YourFeatureController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    # Policy already checked by before_action
    @items = current_account.your_features
    render json: @items
  end

  def create
    authorize YourFeature
    @item = current_account.your_features.create!(permitted_params)
    render json: @item
  end

  private

  def check_authorization
    authorize YourFeature
  end
end
```

#### 3. Service-Level Permission Checks

```ruby
# app/services/conversations/permission_filter_service.rb
class Conversations::PermissionFilterService
  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_has_full_access?
    
    filter_by_permissions
  end

  private

  def user_has_full_access?
    account_user&.administrator? || 
    permissions.include?('conversation_manage')
  end

  def filter_by_permissions
    if permissions.include?('conversation_unassigned_manage')
      # User sees unassigned + their own
      conversations.where(
        'assignee_id IS NULL OR assignee_id = ?', @user.id
      )
    elsif permissions.include?('conversation_participating_manage')
      # User sees only their own
      conversations.where(assignee_id: @user.id)
    else
      # No conversation permissions - but still an agent
      # Route-level blocking should prevent this case
      conversations
    end
  end

  def permissions
    @permissions ||= account_user&.permissions || []
  end

  def account_user
    @account_user ||= AccountUser.find_by(
      account_id: @account.id, 
      user_id: @user.id
    )
  end
end
```

---

## Frontend Policy Implementation

### 1. Constants Definition

```javascript
// app/javascript/dashboard/constants/permissions.js

// All available permissions
export const AVAILABLE_PERMISSIONS = [
  // Conversation permissions
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
  // Feature access permissions
  'contact_manage',
  'report_manage',
  'knowledge_base_manage',
  'campaign_manage',
  'templates_manage',
  // Settings section permissions
  'settings_account_manage',
  'settings_agents_manage',
  // ... etc
];

// Grouped for specific features
export const CONVERSATION_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
];

export const CONTACT_PERMISSIONS = 'contact_manage';
export const REPORTS_PERMISSIONS = 'report_manage';
```

### 2. Permission Helper Functions

```javascript
// app/javascript/dashboard/helper/permissionsHelper.js

export const hasPermissions = (
  requiredPermissions = [],
  availablePermissions = []
) => {
  // Administrators have access to everything
  if (availablePermissions.includes('administrator')) {
    return true;
  }
  // Check if user has ANY of the required permissions
  return requiredPermissions.some(permission =>
    availablePermissions.includes(permission)
  );
};

export const getUserPermissions = (user, accountId) => {
  const currentAccount = getCurrentAccount(user, accountId) || {};
  return currentAccount.permissions || [];
};

export const getCurrentAccount = ({ accounts } = {}, accountId = null) => {
  return accounts.find(account => Number(account.id) === Number(accountId));
};
```

### 3. Route-Level Access Control

```javascript
// app/javascript/dashboard/routes/dashboard/your-feature/routes.js
import { frontendURL } from 'dashboard/helper/URLHelper';

const YOUR_FEATURE_PERMISSIONS = [
  'administrator',
  'your_feature_manage',
];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/your-feature'),
      name: 'your_feature_index',
      meta: {
        permissions: YOUR_FEATURE_PERMISSIONS,
      },
      component: YourFeatureView,
    },
  ],
};
```

### 4. Sidebar Menu Visibility

```javascript
// app/javascript/dashboard/components-next/sidebar/Sidebar.vue

// Define required permissions for menu items
const YOUR_FEATURE_MENU_PERMISSIONS = [
  'administrator',
  'your_feature_manage',
];

const menuItems = computed(() => {
  return [
    // Conditionally include menu item based on permissions
    ...(hasMenuPermission(YOUR_FEATURE_MENU_PERMISSIONS)
      ? [
          {
            name: 'YourFeature',
            label: t('SIDEBAR.YOUR_FEATURE'),
            icon: 'i-lucide-icon',
            to: accountScopedRoute('your_feature_index'),
          },
        ]
      : []),
    // ... other menu items
  ];
});
```

### 5. Component-Level Permission Checks

```vue
<!-- YourComponent.vue -->
<template>
  <div v-if="hasAccess">
    <!-- Feature content -->
  </div>
  <div v-else>
    <!-- Access denied message or redirect -->
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { 
  hasPermissions, 
  getUserPermissions 
} from 'dashboard/helper/permissionsHelper';

const currentUser = useMapGetter('getCurrentUser');
const accountId = useMapGetter('getCurrentAccountId');

const userPermissions = computed(() =>
  getUserPermissions(currentUser.value, accountId.value)
);

const hasAccess = computed(() =>
  hasPermissions(
    ['administrator', 'your_feature_manage'],
    userPermissions.value
  )
);
</script>
```

### 6. Conversation Filtering (Frontend)

```javascript
// app/javascript/dashboard/store/modules/conversations/helpers.js

/**
 * CommMate: Conversation visibility filter based on user permissions
 *
 * Permission hierarchy (permissions stack):
 * - Basic Agent: Only sees conversations assigned to them
 * - + conversation_participating_manage: Also sees conversations where they participate
 * - + conversation_unassigned_manage: Also sees unassigned conversations
 * - conversation_manage: Sees all conversations
 */
export const applyRoleFilter = (
  conversation,
  role,
  permissions,
  currentUserId
) => {
  // Administrators always see all conversations
  if (role === 'administrator') {
    return true;
  }

  // Full conversation management permission = see all
  if (permissions.includes('conversation_manage')) {
    return true;
  }

  const assignee = conversation.meta.assignee;
  const isAssignedToUser = assignee?.id === currentUserId;

  // All agents can see their assigned conversations
  if (isAssignedToUser) {
    return true;
  }

  // Check if user is a participant (not assignee, but added to conversation)
  const participants = conversation.meta.participants || [];
  const isParticipant = participants.some(p => p.id === currentUserId);

  // conversation_participating_manage: can see conversations where they participate
  if (permissions.includes('conversation_participating_manage') && isParticipant) {
    return true;
  }

  // conversation_unassigned_manage: can see unassigned conversations
  const isUnassigned = !assignee;
  if (permissions.includes('conversation_unassigned_manage') && isUnassigned) {
    return true;
  }

  // No permission grants access to this conversation
  return false;
};
```

---

## Adding a New Permission

### Complete Step-by-Step Guide

#### Step 1: Add to AccountUser model (Backend)

```ruby
# app/models/account_user.rb
AVAILABLE_PERMISSIONS = %w[
  conversation_manage
  conversation_unassigned_manage
  conversation_participating_manage
  contact_manage
  report_manage
  knowledge_base_manage
  campaign_manage
  templates_manage
  settings_macros_manage
  settings_account_manage
  settings_agents_manage
  settings_teams_manage
  settings_inboxes_manage
  settings_labels_manage
  settings_custom_attributes_manage
  settings_automation_manage
  settings_agent_bots_manage
  settings_integrations_manage
  your_new_feature_manage  # ← ADD HERE
].freeze
```

#### Step 2: Add to Frontend Constants

```javascript
// app/javascript/dashboard/constants/permissions.js
export const AVAILABLE_PERMISSIONS = [
  // ... existing permissions ...
  'your_new_feature_manage',  // ← ADD HERE
];

// Optional: Create a named export for the permission
export const YOUR_NEW_FEATURE_PERMISSION = 'your_new_feature_manage';
```

#### Step 3: Add Translations

```json
// app/javascript/dashboard/i18n/locale/en/customRole.json
{
  "PERMISSIONS": {
    "CONVERSATION_MANAGE": "Manage all conversations",
    "YOUR_NEW_FEATURE_MANAGE": "Manage your new feature"  // ← ADD HERE
  }
}

// app/javascript/dashboard/i18n/locale/pt_BR/customRole.json
{
  "PERMISSIONS": {
    "YOUR_NEW_FEATURE_MANAGE": "Gerenciar nova funcionalidade"  // ← ADD HERE
  }
}
```

#### Step 4: Create Backend Policy

```ruby
# app/policies/your_new_feature_policy.rb
class YourNewFeaturePolicy < ApplicationPolicy
  def index?
    administrator_or_has_permission?
  end

  def show?
    administrator_or_has_permission?
  end

  def create?
    administrator_or_has_permission?
  end

  def update?
    administrator_or_has_permission?
  end

  def destroy?
    @account_user.administrator?
  end

  private

  def administrator_or_has_permission?
    @account_user.administrator? || 
    @account_user.permissions.include?('your_new_feature_manage')
  end
end
```

#### Step 5: Apply Policy in Controller

```ruby
# app/controllers/api/v1/accounts/your_new_features_controller.rb
class Api::V1::Accounts::YourNewFeaturesController < Api::V1::Accounts::BaseController
  before_action :authorize_access

  def index
    @items = current_account.your_new_features
    render json: @items
  end

  private

  def authorize_access
    authorize YourNewFeature
  end
end
```

#### Step 6: Protect Routes (Frontend)

```javascript
// app/javascript/dashboard/routes/dashboard/your-new-feature/routes.js
import { frontendURL } from 'dashboard/helper/URLHelper';
import YourNewFeatureView from './YourNewFeatureView.vue';

const REQUIRED_PERMISSIONS = ['administrator', 'your_new_feature_manage'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/your-new-feature'),
      name: 'your_new_feature_index',
      meta: {
        permissions: REQUIRED_PERMISSIONS,
      },
      component: YourNewFeatureView,
    },
  ],
};
```

#### Step 7: Add to Sidebar Menu

```javascript
// app/javascript/dashboard/components-next/sidebar/Sidebar.vue
const menuItems = computed(() => {
  return [
    // ... other items ...
    
    // Your new feature menu item
    ...(hasMenuPermission(['administrator', 'your_new_feature_manage'])
      ? [
          {
            name: 'YourNewFeature',
            label: t('SIDEBAR.YOUR_NEW_FEATURE'),
            icon: 'i-lucide-sparkles',
            to: accountScopedRoute('your_new_feature_index'),
          },
        ]
      : []),
  ];
});
```

#### Step 8: Add Sidebar Translation

```json
// app/javascript/dashboard/i18n/locale/en/sidebar.json
{
  "YOUR_NEW_FEATURE": "Your New Feature"
}

// app/javascript/dashboard/i18n/locale/pt_BR/sidebar.json
{
  "YOUR_NEW_FEATURE": "Nova Funcionalidade"
}
```

---

## Conversation Permission Behavior Summary

| Agent Type | Inbox/Conversations Menu | What They See |
|------------|-------------------------|---------------|
| **Basic Agent** (no extra perms) | Visible | Only their assigned conversations |
| + `conversation_participating_manage` | Visible | Assigned + conversations where they participate |
| + `conversation_unassigned_manage` | Visible | Assigned + unassigned conversations |
| + both participating & unassigned | Visible | Assigned + participating + unassigned |
| `conversation_manage` | Visible | All conversations |
| **Administrator** | Visible | All conversations |

**Key Points:**
- All agents have access to Inbox and Conversations menu by default
- Filtering happens at the conversation level, not menu level
- Permissions stack (combine) when multiple are assigned

---

## Common Scenarios

### Customer Support Team

```
- Team Lead → Administrator
- Senior Agents → Agent + conversation_manage, report_manage
- Support Agents → Agent + conversation_participating_manage
- QA Specialists → Agent + conversation_manage, report_manage
```

### Marketing Team Access

```
- Marketing Manager → Agent + campaign_manage, templates_manage
- Marketing Coordinator → Agent + campaign_manage, contact_manage
```

### Limited Dashboard Access

```
- View-Only Reports → Agent + report_manage (no conversation access)
- Template Creator → Agent + templates_manage (no conversation access)
```

---

## Testing Permissions

### Backend (RSpec)

```ruby
# spec/policies/your_feature_policy_spec.rb
require 'rails_helper'

RSpec.describe YourFeaturePolicy do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent_with_permission) { create(:user, account: account) }
  let(:agent_without_permission) { create(:user, account: account) }

  before do
    account_user = agent_with_permission.account_users.find_by(account: account)
    account_user.update!(access_permissions: ['your_feature_manage'])
  end

  describe '#index?' do
    it 'allows administrators' do
      expect(described_class.new(admin, YourFeature.new, account: account)).to be_index
    end

    it 'allows agents with permission' do
      expect(described_class.new(agent_with_permission, YourFeature.new, account: account)).to be_index
    end

    it 'denies agents without permission' do
      expect(described_class.new(agent_without_permission, YourFeature.new, account: account)).not_to be_index
    end
  end
end
```

### Frontend (Vitest)

```javascript
// your-feature.spec.js
import { hasPermissions } from 'dashboard/helper/permissionsHelper';

describe('YourFeature permissions', () => {
  it('allows administrators', () => {
    const permissions = ['administrator'];
    expect(hasPermissions(['your_feature_manage'], permissions)).toBe(true);
  });

  it('allows users with explicit permission', () => {
    const permissions = ['agent', 'your_feature_manage'];
    expect(hasPermissions(['your_feature_manage'], permissions)).toBe(true);
  });

  it('denies users without permission', () => {
    const permissions = ['agent'];
    expect(hasPermissions(['your_feature_manage'], permissions)).toBe(false);
  });
});
```

---

## Security Considerations

1. **Principle of Least Privilege** - Only assign permissions users need
2. **Regular Audits** - Review user permissions quarterly
3. **Separate Accounts** - Use different accounts for different clients
4. **Administrators** - Limit administrator access to key personnel
5. **Backend Enforcement** - Always enforce permissions on the backend, not just frontend

---

## Troubleshooting

### Permissions not taking effect

1. Check the user has been saved with the new permissions
2. Have the user log out and back in
3. Clear browser cache
4. Verify the permission is in `AVAILABLE_PERMISSIONS`

### Check a user's permissions via Rails console

```ruby
user = User.find_by(email: 'user@example.com')
account_user = user.account_users.find_by(account_id: 1)
puts account_user.permissions
# => ["agent", "campaign_manage", "templates_manage"]
```

### Verify route permissions in browser console

```javascript
// In browser developer tools
const state = window.__CHATWOOT_STORE__;
const user = state.getters.getCurrentUser;
const accountId = state.getters.getCurrentAccountId;
const account = user.accounts.find(a => a.id === accountId);
console.log('User permissions:', account.permissions);
```

---

## Related Documentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) - System architecture and enterprise compliance
- [`CORE-MODIFICATIONS.md`](CORE-MODIFICATIONS.md) - List of modified Chatwoot files
- [`DEVELOPMENT.md`](DEVELOPMENT.md) - Development setup and guidelines

---

**Document Version:** 3.0  
**Last Updated:** January 17, 2026  
**Status:** Production-ready with per-user permissions
