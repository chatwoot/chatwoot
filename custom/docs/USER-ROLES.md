# CommMate User Roles & Permissions

Complete guide for managing user roles and permissions in CommMate.

**Last Updated**: January 16, 2026  
**Version**: CommMate v4.8.1+

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

## Additional Permissions

Agents can be granted additional permissions beyond their base role:

| Permission | Description |
|------------|-------------|
| `conversation_manage` | Manage all conversations |
| `conversation_unassigned_manage` | Manage unassigned conversations |
| `conversation_participating_manage` | Manage participating conversations |
| `contact_manage` | Manage contacts (edit, merge, delete) |
| `report_manage` | Access analytics and reports |
| `knowledge_base_manage` | Manage help center articles |
| `campaign_manage` | Manage marketing campaigns |
| `templates_manage` | Manage WhatsApp message templates |

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

### Backend (Rails)

Permissions are stored in `account_users.access_permissions` as a PostgreSQL text array:

```ruby
# AccountUser model
AVAILABLE_PERMISSIONS = %w[
  conversation_manage
  conversation_unassigned_manage
  conversation_participating_manage
  contact_manage
  report_manage
  knowledge_base_manage
  campaign_manage
  templates_manage
].freeze

def permissions
  # Returns base role permissions + access_permissions
  base_permissions = administrator? ? ['administrator'] : ['agent']
  base_permissions + (access_permissions || [])
end
```

### Policy Enforcement

```ruby
# Example: app/policies/campaign_policy.rb
def index?
  @account_user.administrator? || has_campaign_permission?
end

private

def has_campaign_permission?
  @account_user.permissions.include?('campaign_manage')
end
```

### Frontend (Vue)

Permissions flow through the API and are used in routes and components:

```javascript
// permissions are available via the user's account
const currentAccount = getCurrentAccount(user, accountId);
const userPermissions = currentAccount.permissions; // ['agent', 'campaign_manage', ...]

// Check permission
if (userPermissions.includes('campaign_manage')) {
  // Allow access
}
```

---

## Adding New Permissions

### Step 1: Add to AccountUser model

```ruby
# app/models/account_user.rb
AVAILABLE_PERMISSIONS = %w[
  ... existing permissions ...
  your_new_permission  # ADD HERE
].freeze
```

### Step 2: Add to frontend constants

```javascript
// app/javascript/dashboard/constants/permissions.js
export const AVAILABLE_CUSTOM_ROLE_PERMISSIONS = [
  ... existing permissions ...
  'your_new_permission',  // ADD HERE
];
```

### Step 3: Add translation

```json
// app/javascript/dashboard/i18n/locale/en/customRole.json
"PERMISSIONS": {
  "YOUR_NEW_PERMISSION": "Description of permission"
}
```

### Step 4: Update Policy

```ruby
# app/policies/your_feature_policy.rb
def index?
  @account_user.administrator? || 
  @account_user.permissions.include?('your_new_permission')
end
```

---

## Migration from Custom Roles

If upgrading from a previous version with Custom Roles:

1. Run migrations to add `access_permissions` column
2. Data migration automatically copies permissions from custom roles
3. Custom role assignments are cleared
4. Users retain their permissions via `access_permissions`

The migration is handled by:
- `20260116100000_add_access_permissions_to_account_users.rb`
- `20260116100001_migrate_custom_roles_to_access_permissions.rb`

---

## Common Scenarios

### Customer Support Team

```
- Team Lead → Administrator
- Senior Agents → Agent + campaign_manage, report_manage
- Support Agents → Agent (basic)
- QA Specialists → Agent + conversation_manage, report_manage
```

### Marketing Team Access

```
- Marketing Manager → Agent + campaign_manage
- Marketing Coordinator → Agent + campaign_manage, contact_manage
```

### WhatsApp Templates Team

```
- Template Manager → Agent + templates_manage
- Template Creator → Agent + templates_manage
```

---

## Security Considerations

1. **Principle of Least Privilege** - Only assign permissions users need
2. **Regular Audits** - Review user permissions quarterly
3. **Separate Accounts** - Use different accounts for different clients
4. **Administrators** - Limit administrator access to key personnel

---

## Troubleshooting

### Permissions not taking effect

1. Check the user has been saved with the new permissions
2. Have the user log out and back in
3. Clear browser cache

### Check a user's permissions via Rails console

```ruby
user = User.find_by(email: 'user@example.com')
account_user = user.account_users.find_by(account_id: 1)
puts account_user.permissions
# => ["agent", "campaign_manage", "templates_manage"]
```

---

## Related Documentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) - System architecture and enterprise compliance
- [`CORE-MODIFICATIONS.md`](CORE-MODIFICATIONS.md) - List of modified Chatwoot files

---

**Document Version:** 2.0  
**Last Updated:** January 16, 2026  
**Status:** Production-ready with per-user permissions
