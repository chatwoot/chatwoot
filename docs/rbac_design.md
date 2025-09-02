# RBAC Design Document - WeaveSmart Chat

## Current State Analysis

**Existing Chatwoot Roles:**
- `agent` (0) - Basic conversation handling
- `administrator` (1) - Full account management

**Enterprise Custom Roles:**
- Supports custom permission arrays
- 6 permissions: conversation_manage, conversation_unassigned_manage, conversation_participating_manage, contact_manage, report_manage, knowledge_base_manage
- Admin-only role creation/management

## Proposed WSC RBAC Structure

### Core Roles (Built-in)

1. **Owner** - Account owner with all permissions
2. **Admin** - Account administrators with most permissions  
3. **Agent** - Standard support agents
4. **Finance** - Billing and financial data access
5. **Support** - Limited support access
6. **Custom** - Fully customizable roles

### Permission Categories & Granular Permissions

#### **Conversations & Messaging**
- `conversation_view_all` - View all conversations
- `conversation_view_assigned` - View only assigned conversations  
- `conversation_view_participating` - View conversations they participate in
- `conversation_manage_all` - Full conversation management
- `conversation_manage_assigned` - Manage assigned conversations
- `conversation_assign` - Assign conversations to agents
- `conversation_transfer` - Transfer conversations between agents
- `conversation_resolve` - Resolve conversations
- `conversation_reopen` - Reopen resolved conversations
- `conversation_private_notes` - Add private notes
- `conversation_export` - Export conversation data

#### **Contacts & Customer Data**
- `contact_view` - View contact information
- `contact_create` - Create new contacts
- `contact_update` - Update contact details
- `contact_delete` - Delete contacts
- `contact_merge` - Merge duplicate contacts
- `contact_export` - Export contact data
- `contact_import` - Import contact data
- `contact_custom_attributes` - Manage custom attributes

#### **Team & User Management**
- `team_view` - View team members
- `team_invite` - Invite new team members
- `team_manage` - Full team management
- `user_profile_update` - Update user profiles
- `role_assign` - Assign roles to users
- `role_create` - Create custom roles
- `role_manage` - Manage existing roles

#### **Reporting & Analytics**
- `report_view` - View basic reports
- `report_advanced` - Access advanced analytics
- `report_export` - Export report data
- `report_custom` - Create custom reports
- `analytics_view` - View analytics dashboard
- `analytics_export` - Export analytics data

#### **Billing & Finance**
- `billing_view` - View billing information
- `billing_manage` - Manage billing settings
- `invoice_view` - View invoices
- `invoice_download` - Download invoices
- `payment_methods` - Manage payment methods
- `subscription_manage` - Manage subscriptions
- `usage_view` - View usage metrics

#### **Settings & Configuration**
- `settings_account` - Account settings
- `settings_channels` - Channel configuration
- `settings_integrations` - Integration settings
- `settings_webhooks` - Webhook management
- `settings_automation` - Automation rules
- `settings_security` - Security settings
- `settings_advanced` - Advanced configurations

#### **Knowledge Base & Help Center**
- `kb_view` - View knowledge base
- `kb_article_create` - Create articles
- `kb_article_edit` - Edit articles
- `kb_article_delete` - Delete articles
- `kb_category_manage` - Manage categories
- `kb_portal_manage` - Manage portals
- `kb_publish` - Publish content

#### **Channels & Integrations**
- `channel_view` - View channel information
- `channel_create` - Create new channels
- `channel_configure` - Configure channels
- `channel_delete` - Delete channels
- `integration_manage` - Manage integrations
- `webhook_manage` - Manage webhooks

#### **System & Audit**
- `audit_log_view` - View audit logs
- `system_info_view` - View system information
- `feature_flags_view` - View feature flags
- `feature_flags_manage` - Manage feature flags (Admin only)

### Default Role Permissions Matrix

| Permission Category | Owner | Admin | Agent | Finance | Support |
|---------------------|-------|-------|-------|---------|---------|
| **Conversations** | ✅ All | ✅ All | 🔸 Assigned/Participating | ❌ None | 🔸 View Only |
| **Contacts** | ✅ All | ✅ All | 🔸 View/Update | ❌ None | 🔸 View Only |
| **Team Management** | ✅ All | ✅ All | ❌ None | ❌ None | ❌ None |
| **Reporting** | ✅ All | ✅ All | 🔸 Basic | ✅ All | 🔸 Basic |
| **Billing** | ✅ All | ✅ View | ❌ None | ✅ All | ❌ None |
| **Settings** | ✅ All | ✅ All | ❌ None | 🔸 Billing Only | ❌ None |
| **Knowledge Base** | ✅ All | ✅ All | 🔸 Create/Edit | ❌ None | 🔸 View/Create |
| **Channels** | ✅ All | ✅ All | 🔸 View | ❌ None | 🔸 View |
| **System/Audit** | ✅ All | ✅ All | ❌ None | ❌ None | ❌ None |

### Implementation Strategy

1. **Extend CustomRole model** - Add more granular permissions
2. **Enhance AccountUser enum** - Add finance, support, owner roles
3. **Policy classes** - Implement fine-grained permission checks
4. **UI Guards** - Show/hide menu items and actions based on permissions
5. **API Guards** - Enforce permissions at controller level
6. **Audit Trail** - Log all permission-based actions

### Migration Strategy

1. **Backwards Compatible** - Existing administrator/agent roles remain functional
2. **Default Assignments** - Auto-assign appropriate permissions to existing roles
3. **Progressive Enhancement** - New permissions can be added without breaking existing functionality

### Security Considerations

- **Principle of Least Privilege** - Users get minimum required permissions
- **Audit Logging** - All permission changes and usage logged
- **Session Validation** - Re-validate permissions on sensitive operations
- **Role Hierarchy** - Prevent privilege escalation