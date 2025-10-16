# Subscription-Based Feature Gating Plan

## Overview
Implement a tiered subscription system with feature gating for Chatwoot:
- **Free Tier**: Core features (conversations, contacts, basic settings)
- **Pro Tier**: Free + Reports
- **Enterprise Tier**: Pro + Campaigns + Voice Agents

## Current Architecture Analysis

### ✅ What Already Exists
Chatwoot has excellent enterprise infrastructure in place:

1. **Plan Management** (`enterprise/app/models/enterprise/account/plan_usage_and_limits.rb`)
   - `plan_name` stored in `accounts.custom_attributes['plan_name']`
   - `subscribed_features` method to check plan features
   - `usage_limits` for quota management

2. **Billing Integration** (`enterprise/app/services/enterprise/billing/`)
   - Stripe customer creation
   - Stripe webhook handling
   - Already integrated with Stripe!

3. **Authorization** (Pundit policies)
   - Policy-based permissions (e.g., `ReportPolicy`, `CampaignPolicy`, `VapiAgentPolicy`)
   - Enterprise prepend pattern: `ReportPolicy.prepend_mod_with('ReportPolicy')`
   - Can extend policies without modifying core

4. **Frontend Structure**
   - Route-based permissions system
   - Sidebar component structure for hiding/showing features

## Implementation Plan

### Phase 1: Define Subscription Tiers

#### 1.1 Create Subscription Constants
**File**: `enterprise/app/models/enterprise/concerns/subscription_tiers.rb`

```ruby
module Enterprise::Concerns::SubscriptionTiers
  TIERS = {
    free: {
      name: 'Free',
      features: [
        'conversations',
        'contacts',
        'inboxes',
        'labels',
        'teams',
        'canned_responses',
        'automation',
        'integrations',
        'basic_settings'
      ]
    },
    pro: {
      name: 'Professional',
      features: [
        'conversations',
        'contacts',
        'inboxes',
        'labels',
        'teams',
        'canned_responses',
        'automation',
        'integrations',
        'basic_settings',
        'reports',  # NEW: Pro tier unlocks reports
        'custom_attributes',
        'sla'
      ]
    },
    enterprise: {
      name: 'Enterprise',
      features: [
        'conversations',
        'contacts',
        'inboxes',
        'labels',
        'teams',
        'canned_responses',
        'automation',
        'integrations',
        'basic_settings',
        'reports',
        'custom_attributes',
        'sla',
        'campaigns',      # NEW: Enterprise only
        'voice_agents',   # NEW: Enterprise only
        'captain',        # AI features
        'audit_logs',
        'custom_roles'
      ]
    }
  }.freeze

  def plan_tier
    (custom_attributes['plan_name'] || 'free').downcase.to_sym
  end

  def has_feature?(feature_name)
    TIERS.dig(plan_tier, :features)&.include?(feature_name.to_s) || false
  end

  def plan_display_name
    TIERS.dig(plan_tier, :name) || 'Free'
  end
end
```

#### 1.2 Extend Account Model
**File**: `enterprise/app/models/enterprise/concerns/account.rb` (or new file)

```ruby
module Enterprise::Concerns::Account
  include SubscriptionTiers

  # Override subscribed_features to use new tier system
  def subscribed_features
    TIERS.dig(plan_tier, :features) || TIERS[:free][:features]
  end
end
```

### Phase 2: Update Policies for Feature Gating

#### 2.1 Create Base Subscription Policy Helper
**File**: `enterprise/app/policies/concerns/subscription_policy.rb`

```ruby
module Enterprise::Concerns::SubscriptionPolicy
  def has_subscription_feature?(feature_name)
    @user.account.has_feature?(feature_name)
  end

  def require_feature(feature_name)
    @account_user.administrator? && has_subscription_feature?(feature_name)
  end
end
```

#### 2.2 Update Report Policy
**File**: `enterprise/app/policies/enterprise/report_policy.rb`

```ruby
module Enterprise::ReportPolicy
  include Enterprise::Concerns::SubscriptionPolicy

  def view?
    require_feature('reports')
  end
end
```

#### 2.3 Update Campaign Policy
**File**: `enterprise/app/policies/enterprise/campaign_policy.rb`

```ruby
module Enterprise::CampaignPolicy
  include Enterprise::Concerns::SubscriptionPolicy

  def index?
    require_feature('campaigns')
  end

  def create?
    require_feature('campaigns')
  end

  def update?
    require_feature('campaigns')
  end

  def destroy?
    require_feature('campaigns')
  end
end
```

#### 2.4 Update Voice Agent Policy
**File**: `enterprise/app/policies/enterprise/vapi_agent_policy.rb`

```ruby
module Enterprise::VapiAgentPolicy
  include Enterprise::Concerns::SubscriptionPolicy

  def index?
    return true if @user.is_a?(SuperAdmin)

    (@account_user&.administrator? || @account_user&.owner?) &&
      has_subscription_feature?('voice_agents')
  end

  def create?
    return true if @user.is_a?(SuperAdmin)

    (@account_user&.administrator? || @account_user&.owner?) &&
      has_subscription_feature?('voice_agents')
  end

  # ... similar for other actions
end
```

### Phase 3: Frontend Feature Gating

#### 3.1 Create Subscription Mixin
**File**: `app/javascript/dashboard/mixins/subscriptionFeatures.js`

```javascript
export default {
  computed: {
    currentPlan() {
      return this.$store.getters['getCurrentAccount']?.custom_attributes?.plan_name || 'free';
    },

    subscribedFeatures() {
      const features = {
        free: ['conversations', 'contacts', 'inboxes', 'labels', 'teams', 'canned_responses', 'automation', 'integrations', 'basic_settings'],
        pro: ['conversations', 'contacts', 'inboxes', 'labels', 'teams', 'canned_responses', 'automation', 'integrations', 'basic_settings', 'reports', 'custom_attributes', 'sla'],
        enterprise: ['conversations', 'contacts', 'inboxes', 'labels', 'teams', 'canned_responses', 'automation', 'integrations', 'basic_settings', 'reports', 'custom_attributes', 'sla', 'campaigns', 'voice_agents', 'captain', 'audit_logs', 'custom_roles']
      };

      return features[this.currentPlan.toLowerCase()] || features.free;
    },

    hasFeature() {
      return (featureName) => {
        return this.subscribedFeatures.includes(featureName);
      };
    }
  }
};
```

#### 3.2 Update Sidebar to Hide Features
**File**: Modify `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

Add computed property to filter menu items:

```javascript
computed: {
  visibleMenuItems() {
    return this.menuItems.filter(item => {
      // Check if item requires subscription feature
      if (item.requiredFeature) {
        return this.hasFeature(item.requiredFeature);
      }
      return true;
    });
  }
}
```

#### 3.3 Update Route Definitions
**Files to update:**
- `app/javascript/dashboard/routes/dashboard/settings/reports/reports.routes.js`
- `app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js`
- `app/javascript/dashboard/routes/dashboard/voiceAgents/voiceAgents.routes.js`

Add meta field:

```javascript
{
  path: 'reports',
  name: 'reports',
  meta: {
    permissions: ['administrator'],
    requiredFeature: 'reports',  // NEW
    requiredPlan: 'pro'  // NEW
  },
  component: ReportsWrapper
}
```

#### 3.4 Create Route Guard
**File**: Update router to check subscription

```javascript
router.beforeEach((to, from, next) => {
  if (to.meta.requiredFeature) {
    const account = store.getters['getCurrentAccount'];
    const planName = account?.custom_attributes?.plan_name || 'free';

    // Check if user has required feature
    if (!accountHasFeature(planName, to.meta.requiredFeature)) {
      // Redirect to paywall or upgrade page
      next({ name: 'billing_upgrade', query: { feature: to.meta.requiredFeature } });
      return;
    }
  }
  next();
});
```

#### 3.5 Create Paywall Component
**File**: `app/javascript/dashboard/components-next/Paywall.vue`

```vue
<template>
  <div class="paywall-container">
    <div class="paywall-icon">🔒</div>
    <h2>{{ featureTitle }} requires {{ requiredPlan }} plan</h2>
    <p>Upgrade your subscription to access this feature.</p>

    <div class="plans-comparison">
      <div v-for="plan in availablePlans" :key="plan.tier" class="plan-card">
        <h3>{{ plan.name }}</h3>
        <ul>
          <li v-for="feature in plan.features" :key="feature">
            {{ feature }}
          </li>
        </ul>
        <Button @click="upgradeTo(plan.tier)">
          Upgrade to {{ plan.name }}
        </Button>
      </div>
    </div>
  </div>
</template>
```

### Phase 4: API Endpoint Protection

#### 4.1 Update Controllers
**Files to update:**
- `app/controllers/api/v1/accounts/reports_controller.rb`
- `app/controllers/api/v1/accounts/campaigns_controller.rb`
- `app/controllers/api/v1/accounts/vapi_agents_controller.rb`

Add before_action:

```ruby
before_action :check_subscription_feature

private

def check_subscription_feature
  required_feature = self.class::REQUIRED_FEATURE
  unless current_account.has_feature?(required_feature)
    render json: {
      error: 'Subscription required',
      required_plan: required_plan_for(required_feature),
      feature: required_feature
    }, status: :forbidden
  end
end

def required_plan_for(feature)
  case feature
  when 'reports' then 'pro'
  when 'campaigns', 'voice_agents' then 'enterprise'
  else 'free'
  end
end
```

### Phase 5: Billing Integration (Optional - Use Existing Stripe)

Chatwoot already has Stripe integration! Just need to configure:

#### 5.1 Update Stripe Webhook Handler
**File**: `enterprise/app/services/enterprise/billing/handle_stripe_event_service.rb`

Ensure it updates `custom_attributes['plan_name']` when subscription changes.

#### 5.2 Create Upgrade Flow
**File**: `enterprise/app/controllers/enterprise/api/v1/billing_controller.rb`

```ruby
def create_checkout_session
  session = Stripe::Checkout::Session.create(
    customer: current_account.stripe_customer_id,
    line_items: [{
      price: params[:price_id],
      quantity: 1
    }],
    mode: 'subscription',
    success_url: dashboard_url(account_id: current_account.id, success: true),
    cancel_url: dashboard_url(account_id: current_account.id)
  )

  render json: { url: session.url }
end
```

### Phase 6: Database Migration (if needed)

Only if you need to add new columns (probably not needed - `custom_attributes` is already JSONB):

```ruby
# Migration not needed - use existing custom_attributes field
# Just set: account.custom_attributes['plan_name'] = 'pro'
```

## Alternative: Use Clerk Instead of Stripe

If you prefer Clerk over existing Stripe integration:

### Clerk Integration Steps

1. **Install Clerk SDK**
```bash
npm install @clerk/clerk-sdk-node
```

2. **Configure Clerk Organization Metadata**
Set organization metadata with subscription tier:
```javascript
await clerkClient.organizations.updateMetadata(organizationId, {
  publicMetadata: {
    subscriptionTier: 'pro',
    features: ['reports', 'custom_attributes']
  }
});
```

3. **Sync Clerk to Chatwoot**
```ruby
# Webhook handler for Clerk
class Webhooks::ClerkController < ActionController::API
  def handle_webhook
    event = Clerk::Webhook.verify(request.body.read, request.headers)

    if event.type == 'organization.updated'
      account = Account.find_by(clerk_org_id: event.data.id)
      account.update(
        custom_attributes: account.custom_attributes.merge(
          plan_name: event.data.public_metadata.subscription_tier
        )
      )
    end
  end
end
```

## Testing Plan

1. **Unit Tests**
```ruby
# spec/models/account_spec.rb
RSpec.describe Account do
  describe '#has_feature?' do
    it 'allows reports for pro tier' do
      account = create(:account, custom_attributes: { plan_name: 'pro' })
      expect(account.has_feature?('reports')).to be true
    end

    it 'denies campaigns for pro tier' do
      account = create(:account, custom_attributes: { plan_name: 'pro' })
      expect(account.has_feature?('campaigns')).to be false
    end
  end
end
```

2. **Policy Tests**
```ruby
# spec/policies/report_policy_spec.rb
RSpec.describe ReportPolicy do
  it 'allows view for pro+ plans' do
    account = create(:account, custom_attributes: { plan_name: 'pro' })
    user = create(:user, :administrator, account: account)
    expect(ReportPolicy.new(user, nil).view?).to be true
  end
end
```

3. **Integration Tests**
```ruby
# spec/requests/api/v1/reports_spec.rb
describe 'GET /api/v1/accounts/:id/reports' do
  it 'returns 403 for free tier' do
    account = create(:account, custom_attributes: { plan_name: 'free' })
    get "/api/v1/accounts/#{account.id}/reports"
    expect(response).to have_http_status(:forbidden)
  end
end
```

## Rollout Strategy

### Phase 1: Backend (Week 1)
- [ ] Add SubscriptionTiers concern
- [ ] Update policies with feature checks
- [ ] Add controller guards
- [ ] Write tests

### Phase 2: Frontend (Week 2)
- [ ] Create subscription mixin
- [ ] Add route guards
- [ ] Build paywall component
- [ ] Update sidebar filtering

### Phase 3: Billing (Week 3)
- [ ] Configure Stripe prices (or Clerk tiers)
- [ ] Test webhook handling
- [ ] Create upgrade flow UI

### Phase 4: Testing & Refinement (Week 4)
- [ ] End-to-end testing
- [ ] Migration plan for existing accounts
- [ ] Documentation

## Configuration Example

Set plan for an account:
```ruby
# Rails console
account = Account.find(1)
account.custom_attributes['plan_name'] = 'enterprise'
account.save!
```

Or via Stripe webhook (already handled in existing code).

## Migration Plan for Existing Users

```ruby
# Set all existing accounts to free tier
Account.find_each do |account|
  account.custom_attributes['plan_name'] ||= 'free'
  account.save
end

# Optionally: Set certain accounts to pro/enterprise based on criteria
Account.where('agents_count > 5').find_each do |account|
  account.custom_attributes['plan_name'] = 'pro'
  account.save
end
```

## Summary

**Recommendation**: Use the existing Stripe integration that Chatwoot already has. It's battle-tested and integrated into the enterprise module.

**Why not Clerk?**
- Chatwoot already has Stripe billing
- Less dependencies
- More control over pricing
- Clerk is better for auth, not billing

**Key Benefits of This Approach:**
1. ✅ Leverages existing infrastructure
2. ✅ Follows Chatwoot's enterprise prepend pattern
3. ✅ Minimal database changes (uses existing JSONB fields)
4. ✅ Clean separation of concerns
5. ✅ Easy to test and maintain
6. ✅ Graceful degradation (free tier gets core features)

**Next Steps:**
1. Decide: Stripe (recommended) or Clerk
2. Define exact pricing for Pro/Enterprise tiers
3. Start with Phase 1 (backend implementation)
4. Test thoroughly before frontend rollout
