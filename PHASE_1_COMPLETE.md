# Phase 1: Backend Subscription System - COMPLETE ✅

## What Was Built

### 1. Subscription Tier System
**File**: `enterprise/app/models/enterprise/concerns/subscription_tiers.rb`

Three subscription tiers for **Unlocking Tech** customers:
- **Basic (Free)**: Core Chatwoot features
- **Professional**: Basic + Reports
- **Premium**: Professional + Campaigns + Voice Agents

**Storage**: Uses `custom_attributes['subscription_tier']` (separate from Chatwoot's `plan_name`)

### 2. Account Model Integration
**File**: `enterprise/app/models/enterprise/concerns/account.rb`

Added methods to Account model:
- `subscription_tier` - Get current tier (basic/professional/premium)
- `has_subscription_feature?(feature_name)` - Check if feature is available
- `subscription_display_name` - Human-readable tier name
- `required_tier_for_feature(feature_name)` - Get minimum tier for feature
- `subscription_features` - List all available features

### 3. Policy Authorization
**Files Created**:
- `enterprise/app/policies/concerns/subscription_policy.rb` - Helper methods
- `enterprise/app/policies/enterprise/report_policy.rb` - Reports (Professional+)
- `enterprise/app/policies/enterprise/campaign_policy.rb` - Campaigns (Premium only)
- `enterprise/app/policies/enterprise/vapi_agent_policy.rb` - Voice Agents (Premium only)

### 4. Controller Protection
**Files Created**:
- `enterprise/app/controllers/concerns/subscription_check.rb` - Controller concern
- `enterprise/app/controllers/enterprise/api/v1/accounts/reports_controller.rb`
- `enterprise/app/controllers/enterprise/api/v1/accounts/campaigns_controller.rb`
- `enterprise/app/controllers/enterprise/api/v1/accounts/vapi_agents_controller.rb`

Returns `402 Payment Required` with upgrade information when access denied.

## How to Test

### 1. Set Subscription Tier for an Account

```ruby
# Rails console
rails console

# Set account to Basic (Free) tier
account = Account.find(1)
account.custom_attributes['subscription_tier'] = 'basic'
account.save!

# Set to Professional tier
account.custom_attributes['subscription_tier'] = 'professional'
account.save!

# Set to Premium tier
account.custom_attributes['subscription_tier'] = 'premium'
account.save!
```

### 2. Test Feature Checks

```ruby
# In Rails console
account = Account.find(1)

# Check current tier
account.subscription_tier
# => :basic (or :professional, :premium)

# Check if has feature
account.has_subscription_feature?('reports')
# => false (if basic), true (if professional or premium)

account.has_subscription_feature?('campaigns')
# => false (unless premium)

account.has_subscription_feature?('voice_agents')
# => false (unless premium)

# Get all features
account.subscription_features
# => ["conversations", "contacts", "inboxes", ...]
```

### 3. Test API Access

```bash
# Test with Basic tier account - should get 402 error
curl -X GET "http://localhost:3000/api/v1/accounts/1/reports" \
  -H "api_access_token: YOUR_TOKEN"

# Expected response:
# {
#   "error": "Subscription upgrade required",
#   "message": "This feature requires Professional subscription",
#   "feature": "reports",
#   "current_tier": "basic",
#   "required_tier": "professional",
#   "upgrade_url": "/app/accounts/1/billing/upgrade?feature=reports"
# }
```

### 4. Test Policy Authorization

```ruby
# In Rails console
user = User.find(1)
account_user = user.account_users.first

# Test report policy
policy = ReportPolicy.new(user, nil)
policy.view?
# => false (if basic tier), true (if professional or premium tier)

# Test campaign policy
policy = CampaignPolicy.new(user, nil)
policy.create?
# => false (unless premium tier)

# Test voice agent policy
policy = VapiAgentPolicy.new(user, nil)
policy.create?
# => false (unless premium tier)
```

## Feature Matrix

| Feature | Basic (Free) | Professional | Premium |
|---------|--------------|--------------|---------|
| Conversations | ✅ | ✅ | ✅ |
| Contacts | ✅ | ✅ | ✅ |
| Inboxes | ✅ | ✅ | ✅ |
| Labels | ✅ | ✅ | ✅ |
| Teams | ✅ | ✅ | ✅ |
| Canned Responses | ✅ | ✅ | ✅ |
| Automation | ✅ | ✅ | ✅ |
| Integrations | ✅ | ✅ | ✅ |
| Webhooks | ✅ | ✅ | ✅ |
| **Reports** | ❌ | ✅ | ✅ |
| **Advanced Reports** | ❌ | ✅ | ✅ |
| **Custom Attributes** | ❌ | ✅ | ✅ |
| **Campaigns** | ❌ | ❌ | ✅ |
| **Voice Agents** | ❌ | ❌ | ✅ |

## Key Differences from Chatwoot Enterprise

| Aspect | Chatwoot Enterprise | Unlocking Tech Subscriptions |
|--------|---------------------|------------------------------|
| **Attribute Name** | `plan_name` | `subscription_tier` |
| **Purpose** | Chatwoot licensing | Your customer subscriptions |
| **Tiers** | Enterprise/Self-hosted | Basic/Professional/Premium |
| **Features** | Captain, SLA, Audit Logs | Reports, Campaigns, Voice Agents |
| **Payment** | To Chatwoot | To You (Unlocking Tech) |

## Quick Setup Guide

### For New Accounts (Default to Basic)

```ruby
# Add this to your account creation logic
account.custom_attributes['subscription_tier'] = 'basic'
```

### For Existing Accounts (Migration)

```ruby
# Set all existing accounts to basic tier
Account.find_each do |account|
  account.custom_attributes['subscription_tier'] ||= 'basic'
  account.save
end
```

### For Testing Specific Tiers

```ruby
# Upgrade test account to Professional
account = Account.find_by(name: 'Test Account')
account.custom_attributes['subscription_tier'] = 'professional'
account.save!

# Upgrade to Premium
account.custom_attributes['subscription_tier'] = 'premium'
account.save!
```

## Error Responses

### 402 Payment Required
When accessing a feature not in current tier:

```json
{
  "error": "Subscription upgrade required",
  "message": "This feature requires Professional subscription",
  "feature": "reports",
  "current_tier": "basic",
  "required_tier": "professional",
  "upgrade_url": "/app/accounts/1/billing/upgrade?feature=reports"
}
```

### 403 Forbidden
When user doesn't have role permissions (even with subscription):

```json
{
  "error": "Forbidden"
}
```

## Next Steps (Phase 2: Frontend)

1. Create frontend subscription checking mixin
2. Add route guards for protected pages
3. Build paywall component
4. Update sidebar to hide unavailable features
5. Add upgrade prompts in UI

## Testing Checklist

- [x] SubscriptionTiers concern created
- [x] Account model includes SubscriptionTiers
- [x] Policy helpers created
- [x] ReportPolicy updated with subscription check
- [x] CampaignPolicy updated with subscription check
- [x] VapiAgentPolicy updated with subscription check
- [x] Controller concern created
- [x] Example controllers created
- [ ] Manual testing with different tiers
- [ ] Integration tests written
- [ ] Policy tests written

## Files Created/Modified

### Created:
1. `enterprise/app/models/enterprise/concerns/subscription_tiers.rb`
2. `enterprise/app/policies/concerns/subscription_policy.rb`
3. `enterprise/app/policies/enterprise/campaign_policy.rb`
4. `enterprise/app/policies/enterprise/vapi_agent_policy.rb`
5. `enterprise/app/controllers/concerns/subscription_check.rb`
6. `enterprise/app/controllers/enterprise/api/v1/accounts/reports_controller.rb`
7. `enterprise/app/controllers/enterprise/api/v1/accounts/campaigns_controller.rb`
8. `enterprise/app/controllers/enterprise/api/v1/accounts/vapi_agents_controller.rb`

### Modified:
1. `enterprise/app/models/enterprise/concerns/account.rb` (added include)
2. `enterprise/app/policies/enterprise/report_policy.rb` (added subscription check)

## Notes

- All code is in `enterprise/` folder - won't affect OSS Chatwoot
- Uses separate attribute name to avoid conflicts
- Compatible with existing Chatwoot Enterprise Edition
- Super Admins bypass all subscription checks
- Preserves existing custom role permissions
