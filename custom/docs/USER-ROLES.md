# CommMate User Roles & Permissions

Complete guide for managing user roles and permissions in CommMate.

**Last Updated**: December 2, 2025  
**Version**: CommMate v4.8.0.1

## 🎭 Available User Roles

Your Chatwoot installation now has **5 user levels** available:

| Role | Level | Permissions | Use Case |
|------|-------|-------------|----------|
| **Administrator** | Built-in | Full access to everything | Account owners, IT admins |
| **Agent** | Built-in | Handle conversations, basic access | Customer support agents |
| **Manager** | Custom | Team management, reports, conversations | Team leads, supervisors |
| **Supervisor** | Custom | View all conversations, manage team | QA, monitoring |
| **Read-Only** | Custom | View only access | Auditors, observers, trainees |

---

## 🔐 Permission Levels Explained

### Administrator (Built-in)
**Full access including:**
- ✅ All conversations (assigned, unassigned, all inboxes)
- ✅ Account settings & billing
- ✅ Add/remove team members
- ✅ Create/delete inboxes
- ✅ Configure integrations
- ✅ Access all reports
- ✅ Manage automation rules
- ✅ Delete conversations
- ✅ Export data

**Best for:** Account owners, IT administrators

---

### Agent (Built-in)
**Basic conversation handling:**
- ✅ View assigned conversations
- ✅ Reply to messages
- ✅ Add notes (private)
- ✅ Add labels
- ✅ Change conversation status
- ✅ View contact details
- ❌ Cannot access settings
- ❌ Cannot view unassigned conversations (unless given access)
- ❌ Cannot manage other agents

**Best for:** Customer support agents, chat operators

---

### Manager (Custom Role)
**Team leadership access:**
- ✅ All conversation management
- ✅ View all conversations (assigned/unassigned)
- ✅ Manage contacts
- ✅ Access all reports & analytics
- ✅ Manage marketing campaigns
- ✅ Add/remove agents
- ✅ Manage teams
- ✅ Manage labels & tags
- ❌ Cannot change account settings
- ❌ Cannot configure inboxes/integrations

**Best for:** Team leads, department managers, marketing coordinators

---

### Supervisor (Custom Role)
**Quality assurance & monitoring:**
- ✅ View all conversations
- ✅ Manage conversations (assign, resolve)
- ✅ Access reports
- ✅ View contact information
- ✅ Manage agent assignments
- ❌ Cannot modify account settings
- ❌ Cannot manage teams
- ❌ Cannot configure system

**Best for:** QA specialists, supervisors, auditors

---

### Read-Only (Custom Role)
**View-only access:**
- ✅ View conversations (read-only)
- ✅ View contact information
- ❌ Cannot reply to messages
- ❌ Cannot modify anything
- ❌ Cannot access settings

**Best for:** Observers, trainees, external auditors

---

## 👥 Assigning Roles to Users

### In Chatwoot UI

1. Go to **Settings → Agents**
2. Click on a user to edit
3. Select **Custom Role** dropdown
4. Choose from: Supervisor, Manager, or Read-Only
5. Click **Save**

### Via Database (for bulk updates)

```bash
# Assign Manager role to a user
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "UPDATE account_users SET custom_role_id = 2 WHERE user_id = USER_ID AND account_id = 1;"'

# Check user roles
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "SELECT u.name, u.email, au.role, cr.name as custom_role FROM users u JOIN account_users au ON u.id = au.user_id LEFT JOIN custom_roles cr ON au.custom_role_id = cr.id WHERE au.account_id = 1;"'
```

---

## 🆕 Managing Custom Roles

### Via Super Admin Console (Recommended)

**Access**: http://localhost:3333/super_admin/custom_roles

1. Navigate to Super Admin Console
2. Click **"Custom Roles"** in the main navigation
3. Click **"New Custom Role"** button
4. Fill in:
   - **Name**: Role name (e.g., "QA Specialist")
   - **Description**: What this role does
   - **Permissions**: Check boxes for permissions to grant
5. Click **Save**

**Features**:
- ✅ View all existing custom roles
- ✅ Create new roles with checkbox permissions
- ✅ Edit role permissions anytime
- ✅ Delete unused roles
- ✅ See which accounts use each role

### Available Permissions

All permissions are automatically loaded from `CustomRole::PERMISSIONS`:

```
Conversations:
- conversation_manage                  # Manage all conversations
- conversation_unassigned_manage       # Manage unassigned conversations
- conversation_participating_manage    # Manage participating conversations

Contacts:
- contact_manage                       # Manage contacts (edit, merge, delete)

Reports:
- report_manage                        # Access analytics and reports

Knowledge Base:
- knowledge_base_manage                # Manage help center articles and portals

Campaigns:
- campaign_manage                      # Manage marketing campaigns (NEW in v4.8.0.1)
```

**Note**: Permissions are dynamically loaded. New permissions added to `CustomRole::PERMISSIONS` automatically appear in the Super Admin UI.

---

## 🔧 How Permissions Work (For Developers)

### Architecture

**Permissions are defined in CODE, stored in DATABASE:**

**1. Permission Definition (Code):**
```ruby
# enterprise/app/models/custom_role.rb
class CustomRole < ApplicationRecord
  PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
    campaign_manage
  ].freeze
end
```

**2. Permission Storage (Database):**
```sql
-- Table: custom_roles
-- Column: permissions (text array)
-- Example: ["conversation_manage", "report_manage"]
```

**3. Permission Enforcement (Policies):**
```ruby
# app/policies/campaign_policy.rb
def index?
  @account_user.administrator? || 
  @account_user.custom_role&.permissions&.include?('campaign_manage')
end
```

### Why This Design?

**Code-defined permissions:**
- ✅ Permissions are application features (not data)
- ✅ Policies check specific permission strings
- ✅ Type-safe and predictable
- ✅ Automatically appear in Super Admin UI

**Database-stored selections:**
- ✅ Each role can have different subset
- ✅ User assignments reference role ID
- ✅ Flexible per-account customization

### Adding New Permission

**Step 1: Add to PERMISSIONS constant**
```ruby
# enterprise/app/models/custom_role.rb
PERMISSIONS = %w[
  conversation_manage
  ...existing permissions...
  your_new_permission  # ADD HERE
].freeze
```

**Step 2: Add to frontend constants**
```javascript
// app/javascript/dashboard/constants/permissions.js
export const AVAILABLE_CUSTOM_ROLE_PERMISSIONS = [
  'conversation_manage',
  ...
  'your_new_permission',  // ADD HERE
];
```

**Step 3: Add translation**
```json
// app/javascript/dashboard/i18n/locale/en/customRole.json
"PERMISSIONS": {
  "YOUR_NEW_PERMISSION": "Description of permission"
}
```

**Step 4: Update Policy**
```ruby
# app/policies/your_feature_policy.rb
def index?
  @account_user.administrator? || 
  @account_user.custom_role&.permissions&.include?('your_new_permission')
end
```

**Step 5: (Optional) Migration to add to existing roles**
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_new_permission_to_roles.rb
CustomRole.where(name: 'Manager').find_each do |role|
  role.permissions << 'your_new_permission' unless role.permissions.include?('your_new_permission')
  role.save!
end
```

**Result:** Permission automatically appears in Super Admin UI checkboxes!

### Database Structure

```sql
CREATE TABLE custom_roles (
  id BIGINT PRIMARY KEY,
  account_id BIGINT NOT NULL,
  name VARCHAR NOT NULL,
  description VARCHAR,
  permissions TEXT[] DEFAULT '{}',  -- Array of permission strings
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  UNIQUE(account_id, name)  -- Name must be unique per account
);
```

**Example Data:**
```ruby
#<CustomRole 
  id: 1, 
  name: "Manager", 
  account_id: 1,
  permissions: ["conversation_manage", "contact_manage", "report_manage", "campaign_manage"],
  ...
>
```

### Create Custom Role via Database

```sql
INSERT INTO custom_roles (
  name,
  description,
  account_id,
  permissions,
  created_at,
  updated_at
) VALUES (
  'Custom Role Name',
  'Description of what this role can do',
  1,  -- Account ID
  ARRAY[
    'conversation_manage',
    'contact_view',
    'report_manage'
  ],
  NOW(),
  NOW()
);
```

### Example: Create "Night Shift Agent" Role

```bash
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "INSERT INTO custom_roles (name, description, account_id, permissions, created_at, updated_at) VALUES ('\''Night Shift Agent'\'', '\''Limited permissions for night shift'\'', 1, '\''{conversation_view,conversation_manage}'\'', NOW(), NOW());"'
```

---

## 📊 View All Roles & Users

### Check All Custom Roles

```bash
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "SELECT id, name, description, permissions FROM custom_roles WHERE account_id = 1;"'
```

### View Users with Their Roles

```bash
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "
SELECT 
  u.id,
  u.name,
  u.email,
  CASE 
    WHEN au.role = 0 THEN '\''Agent'\''
    WHEN au.role = 1 THEN '\''Administrator'\''
  END as base_role,
  cr.name as custom_role
FROM users u
JOIN account_users au ON u.id = au.user_id
LEFT JOIN custom_roles cr ON au.custom_role_id = cr.id
WHERE au.account_id = 1
ORDER BY u.name;
"'
```

---

## 🎯 Common Role Scenarios

### Scenario 1: Customer Support Team

```
- Team Lead → Administrator
- Senior Agents → Manager (full conversation + reports access)
- Agents → Agent (basic conversation handling)
- New Trainees → Read-Only (observe conversations)
- QA Team → Supervisor (monitor all conversations)
```

### Scenario 2: Multi-Department

```
- Department Head → Manager (their department only)
- Senior Support → Supervisor (cross-department visibility)  
- Support Agents → Agent (assigned conversations)
- Analytics Team → Read-Only (data analysis)
```

### Scenario 3: External Contractors

```
- Internal Team → Administrator/Manager
- Contractors → Custom role with limited inbox access
- Auditors → Read-Only
```

---

## ⚙️ Role Configuration Best Practices

### 1. Principle of Least Privilege
Only give permissions that users absolutely need.

### 2. Regular Role Audits
Review who has what access quarterly.

### 3. Separate Accounts for Different Customers
- Account #1 (CommMate) - Your internal team
- Account #2 (Redemac) - Redemac team
- Each account has independent roles

### 4. Custom Roles Per Account
Each account can have its own set of custom roles with different permissions.

---

## 🔄 Managing Roles

### Assign Custom Role to User

```bash
# Get the custom role ID
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "SELECT id, name FROM custom_roles WHERE account_id = 1;"'

# Assign role to user (replace USER_ID and ROLE_ID)
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "UPDATE account_users SET custom_role_id = ROLE_ID WHERE user_id = USER_ID AND account_id = 1;"'
```

### Remove Custom Role (Back to Base Role)

```bash
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "UPDATE account_users SET custom_role_id = NULL WHERE user_id = USER_ID AND account_id = 1;"'
```

### Delete a Custom Role

```bash
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "DELETE FROM custom_roles WHERE id = ROLE_ID AND account_id = 1;"'
```

---

## 📝 Your Current Roles

### Account #1 (CommMate)
- ✅ Administrator (built-in)
- ✅ Agent (built-in)
- ✅ Supervisor (custom) - NEW!
- ✅ Manager (custom) - NEW!
- ✅ Read-Only (custom) - NEW!

### Account #2 (Redemac Adams)
- ✅ Administrator (built-in)
- ✅ Agent (built-in)
- ✅ Supervisor (custom) - NEW!
- ✅ Manager (custom) - NEW!
- ✅ Read-Only (custom) - NEW!

---

## 🎓 How to Use Custom Roles

### In Chatwoot UI

1. **Invite a new agent** or **edit existing agent**
2. In the agent form, you'll see **"Custom Role"** dropdown
3. Select one of your custom roles
4. Save

The agent will now have only the permissions defined in that custom role.

### Testing Roles

1. Create a test user with a custom role
2. Log in as that user (in incognito window)
3. Verify they only see permitted features
4. Adjust permissions as needed

---

## 🔒 Security Considerations

### 1. Never Give Full Admin to Third Parties
Use custom roles like Supervisor or Manager instead.

### 2. Audit Logs
Chatwoot tracks who did what - useful for accountability.

### 3. Regular Permission Reviews
Check who has access to sensitive data quarterly.

### 4. Separate Accounts for Clients
Don't mix internal and client users in the same account.

---

## 📞 Support & Documentation

### Chatwoot Role Documentation
- [Agent Management](https://www.chatwoot.com/docs/user-guide/add-agent-settings)
- [Custom Roles](https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables#custom-roles)

### Get Role IDs

```bash
# List all roles for an account
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "SELECT id, name FROM custom_roles WHERE account_id = 1;"'
```

### Check User's Current Role

```bash
# Replace USER_EMAIL with actual email
ssh root@200.98.72.137 'docker exec postgres-chatwoot psql -U chatwoot_user -d chatwoot -c "
SELECT 
  u.name,
  u.email,
  au.role as base_role,
  cr.name as custom_role_name
FROM users u
JOIN account_users au ON u.id = au.user_id
LEFT JOIN custom_roles cr ON au.custom_role_id = cr.id
WHERE u.email = '\''USER_EMAIL'\'' AND au.account_id = 1;
"'
```

---

**Last Updated**: Oct 7, 2025  
**Status**: ✅ Custom roles enabled and configured for both accounts

