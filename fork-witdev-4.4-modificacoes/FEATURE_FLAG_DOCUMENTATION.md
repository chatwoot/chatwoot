# Feature Flag System Documentation

## Overview

The feature flag system provides account-scoped feature management with global fallbacks, enabling gradual rollouts and instant rollbacks without requiring deployments.

## Usage Patterns

### Backend Usage

#### Basic Pattern (as documented in task requirements)
```ruby
# Check if feature is enabled for a specific account
Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)

# Check global feature flag (no account scoping)
Feature.get(:SOCIALWISE_RICH_DASHBOARD)
```

#### Alternative Methods
```ruby
# Check if feature is enabled globally
Feature.enabled_globally?(:SOCIALWISE_RICH_DASHBOARD)

# Check if feature is enabled for specific account
Feature.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account_id)
```

#### Account-Specific Flag Management
```ruby
# Enable feature for specific account
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id, true)

# Disable feature for specific account
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id, false)

# Remove account-specific flag (falls back to global)
Feature.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id)

# Get all accounts with feature enabled
account_ids = Feature.accounts_with_flag(:SOCIALWISE_RICH_DASHBOARD)
```

#### Bulk Operations for Gradual Rollout
```ruby
# Enable feature for multiple accounts
AccountFeatureFlag.bulk_enable(:SOCIALWISE_RICH_DASHBOARD, [account1.id, account2.id])

# Disable feature for multiple accounts
AccountFeatureFlag.bulk_disable(:SOCIALWISE_RICH_DASHBOARD, [account1.id, account2.id])
```

### Frontend Usage

The feature flag is automatically exposed to the frontend via the global config endpoint:

```javascript
// Access feature flag in Vue components
const isRichDashboardEnabled = window.globalConfig.SOCIALWISE_RICH_DASHBOARD;

// Check if feature is enabled
if (window.globalConfig.SOCIALWISE_RICH_DASHBOARD) {
  // Render rich message components
} else {
  // Fallback to text rendering
}
```

## Flag Hierarchy

The system follows this priority order:

1. **Account-specific flag** (highest priority)
2. **Global flag** (fallback)
3. **Default false** (if nothing is configured)

### Examples

```ruby
# Global flag: enabled, Account flag: not set
# Result: enabled (falls back to global)
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = "true"
AccountFeatureFlag: none
Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id) # => true

# Global flag: enabled, Account flag: disabled
# Result: disabled (account flag overrides global)
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = "true"
AccountFeatureFlag: enabled = false
Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id) # => false

# Global flag: disabled, Account flag: enabled
# Result: enabled (account flag overrides global)
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = nil
AccountFeatureFlag: enabled = true
Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id) # => true
```

## Gradual Rollout Strategy

### Phase 1: Global Disabled, Select Accounts Enabled
```ruby
# Set global flag to disabled
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = nil

# Enable for beta accounts
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, beta_account_1.id, true)
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, beta_account_2.id, true)
```

### Phase 2: Expand to More Accounts
```ruby
# Bulk enable for more accounts
AccountFeatureFlag.bulk_enable(:SOCIALWISE_RICH_DASHBOARD, [
  account_3.id, account_4.id, account_5.id
])
```

### Phase 3: Global Rollout
```ruby
# Enable globally and remove account-specific flags
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = "true"

# Optional: Clean up account-specific flags
AccountFeatureFlag.where(flag_name: 'SOCIALWISE_RICH_DASHBOARD').destroy_all
```

## Rollback Strategies

### Instant Global Rollback
```ruby
# Disable globally (affects all accounts without account-specific flags)
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = nil
```

### Account-Specific Rollback
```ruby
# Disable for specific problematic accounts
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, problematic_account.id, false)

# Or bulk disable
AccountFeatureFlag.bulk_disable(:SOCIALWISE_RICH_DASHBOARD, [
  problematic_account_1.id, problematic_account_2.id
])
```

### Partial Rollback
```ruby
# Keep global flag enabled but disable for specific accounts
GlobalConfig: SOCIALWISE_RICH_DASHBOARD = "true"
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_with_issues.id, false)
```

## Caching

The system implements multi-level caching for performance:

### Account-Specific Flags
- **Cache Key**: `feature_flag:account:{account_id}:{flag_name}`
- **TTL**: 5 minutes
- **Auto-cleared**: When account flags are created/updated/deleted

### Global Flags
- **Cache**: GlobalConfig system cache
- **TTL**: 1 day (configurable)
- **Auto-cleared**: When InstallationConfig is updated

### Manual Cache Clearing
```ruby
# Clear all feature flag caches
Feature.clear_cache

# Clear specific account cache (done automatically)
Rails.cache.delete("feature_flag:account:#{account_id}:#{flag_name}")
```

## Database Schema

### InstallationConfig (Global Flags)
```sql
-- Global feature flag configuration
INSERT INTO installation_configs (name, serialized_value) 
VALUES ('SOCIALWISE_RICH_DASHBOARD', '{"value": "true"}');
```

### AccountFeatureFlags (Account-Specific Flags)
```sql
-- Account-specific feature flag overrides
CREATE TABLE account_feature_flags (
  id BIGINT PRIMARY KEY,
  account_id BIGINT NOT NULL REFERENCES accounts(id),
  flag_name VARCHAR NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(account_id, flag_name)
);
```

## Supported Flags

Currently supported feature flags:

- `SOCIALWISE_RICH_DASHBOARD`: Enables rich message rendering in dashboard

### Adding New Flags

1. Add flag name to `AccountFeatureFlag::SUPPORTED_FLAGS`
2. Update documentation
3. Add tests for the new flag

```ruby
# In app/models/account_feature_flag.rb
SUPPORTED_FLAGS = %w[
  SOCIALWISE_RICH_DASHBOARD
  NEW_FEATURE_FLAG  # Add new flags here
].freeze
```

## Error Handling

The system is designed to fail gracefully:

```ruby
# Database errors fall back to global config
begin
  account_flag = AccountFeatureFlag.find_by(...)
rescue ActiveRecord::ConnectionNotEstablished
  # Falls back to global flag
end

# Invalid flag names return false
Feature.get(:INVALID_FLAG, account_id) # => false

# Missing accounts return global flag value
Feature.get(:VALID_FLAG, 99999) # => global_flag_value
```

## Monitoring and Metrics

### Tracking Flag Usage
```ruby
# Get accounts with feature enabled
enabled_accounts = Feature.accounts_with_flag(:SOCIALWISE_RICH_DASHBOARD)
Rails.logger.info "SOCIALWISE_RICH_DASHBOARD enabled for #{enabled_accounts.count} accounts"

# Get enabled flags for specific account
enabled_flags = AccountFeatureFlag.enabled_flags_for_account(account_id)
Rails.logger.info "Account #{account_id} has flags: #{enabled_flags.join(', ')}"
```

### Performance Monitoring
```ruby
# Monitor cache hit rates
cache_key = "feature_flag:account:#{account_id}:SOCIALWISE_RICH_DASHBOARD"
cached_value = Rails.cache.read(cache_key)
Rails.logger.info "Cache #{cached_value ? 'HIT' : 'MISS'} for #{cache_key}"
```

## Best Practices

### Development
1. Always use the documented pattern: `Feature.get(:FLAG_NAME, account_id)`
2. Handle both enabled and disabled states in your code
3. Provide meaningful fallbacks when features are disabled
4. Test both global and account-specific flag scenarios

### Deployment
1. Start with global flag disabled for new features
2. Enable for internal/beta accounts first
3. Monitor error rates and performance metrics
4. Gradually expand to more accounts
5. Keep rollback plan ready

### Rollback
1. Monitor error rates after enabling features
2. Have instant rollback capability via global flag
3. Use account-specific rollbacks for isolated issues
4. Document rollback procedures for each feature

## Integration Examples

### Instagram Rich Message Service
```ruby
class Instagram::RichMessageService
  private

  def rich_dashboard_enabled?
    account_id = message.conversation.account_id
    enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)
    
    Rails.logger.info "Rich dashboard enabled: #{enabled} for account #{account_id}"
    enabled
  end
end
```

### Frontend Component
```vue
<template>
  <div>
    <RichMessageComponent 
      v-if="isRichDashboardEnabled" 
      :message="message" 
    />
    <TextMessageComponent 
      v-else 
      :message="message" 
    />
  </div>
</template>

<script>
export default {
  computed: {
    isRichDashboardEnabled() {
      return window.globalConfig.SOCIALWISE_RICH_DASHBOARD;
    }
  }
}
</script>
```

This feature flag system provides the flexibility needed for safe, gradual rollouts while maintaining the ability to quickly rollback if issues arise.