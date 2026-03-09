#!/usr/bin/env ruby
# Check if SOCIALWISE_RICH_DASHBOARD feature is enabled for account 3
# Run with: docker exec chatwit-dev-rails-1 bundle exec rails runner check_rich_dashboard_feature.rb

puts "=== Checking SOCIALWISE_RICH_DASHBOARD Feature ==="

account = Account.find(3)
puts "Account: #{account.name} (ID: #{account.id})"

# Check if feature is enabled
enabled = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
puts "SOCIALWISE_RICH_DASHBOARD enabled: #{enabled}"

# Check account features
puts "\nAccount features:"
account.enabled_features.each do |feature|
  puts "  - #{feature}"
end

# Check if feature exists in global features
feature_config = InstallationConfig.find_by(name: 'FEATURE_SOCIALWISE_RICH_DASHBOARD')
puts "\nGlobal feature config:"
if feature_config
  puts "  Name: #{feature_config.name}"
  puts "  Value: #{feature_config.value}"
else
  puts "  No global config found"
end

# Check account-specific feature config
account_feature = account.account_features.find_by(feature_name: 'SOCIALWISE_RICH_DASHBOARD')
puts "\nAccount-specific feature config:"
if account_feature
  puts "  Feature: #{account_feature.feature_name}"
  puts "  Enabled: #{account_feature.enabled}"
else
  puts "  No account-specific config found"
end

# Enable the feature if not enabled
unless enabled
  puts "\n=== Enabling SOCIALWISE_RICH_DASHBOARD for account 3 ==="
  
  # Try to enable via account features
  account_feature = account.account_features.find_or_create_by(feature_name: 'SOCIALWISE_RICH_DASHBOARD')
  account_feature.update!(enabled: true)
  
  puts "Feature enabled successfully!"
  
  # Verify
  enabled_after = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
  puts "SOCIALWISE_RICH_DASHBOARD enabled after update: #{enabled_after}"
else
  puts "\nFeature is already enabled!"
end