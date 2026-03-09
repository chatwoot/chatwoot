#!/usr/bin/env ruby
# Enable SOCIALWISE_RICH_DASHBOARD feature for account 3
# This can be run in Rails console or as a script

puts "=== Enabling SOCIALWISE_RICH_DASHBOARD for Account 3 ==="

begin
  account = Account.find(3)
  puts "Found account: #{account.name} (ID: #{account.id})"
  
  # Check current status
  current_status = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
  puts "Current status: #{current_status}"
  
  unless current_status
    # Enable the feature
    account_feature = account.account_features.find_or_create_by(feature_name: 'SOCIALWISE_RICH_DASHBOARD')
    account_feature.update!(enabled: true)
    
    puts "✅ Feature enabled successfully!"
    
    # Verify
    new_status = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
    puts "New status: #{new_status}"
  else
    puts "✅ Feature is already enabled!"
  end
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Account 3 not found"
rescue StandardError => e
  puts "❌ Error: #{e.message}"
end

puts "=== Script completed ==="