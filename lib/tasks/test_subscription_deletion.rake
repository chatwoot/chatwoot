namespace :billing do
  desc 'Test subscription deletion webhook handling'
  task test_subscription_deletion: :environment do
    puts '=== Testing Subscription Deletion Handling ==='

    # Find or create a test account
    account = Account.find_by(name: 'Test Subscription Account')
    if account.nil?
      account = Account.create!(
        name: 'Test Subscription Account',
        custom_attributes: {
          'stripe_customer_id' => 'cus_test_123',
          'plan_name' => 'starter',
          'subscription_status' => 'active',
          'subscription_ends_on' => 1.day.ago.strftime('%Y-%m-%d')
        }
      )
      puts "Created test account: #{account.name} (ID: #{account.id})"
    else
      puts "Using existing test account: #{account.name} (ID: #{account.id})"
    end

    # Enable some starter features
    account.enable_features('inbound_emails', 'help_center', 'agent_management', 'prompts')
    account.save!

    puts "\n--- BEFORE Subscription Deletion ---"
    puts "Plan: #{account.custom_attributes['plan_name']}"
    puts "Status: #{account.custom_attributes['subscription_status']}"
    puts "Feature flags value: #{account.feature_flags}"
    puts "Cancel at period end: #{account.custom_attributes['cancel_at_period_end']}"
    puts "Canceled at: #{account.custom_attributes['canceled_at']}"
    puts "Ended at: #{account.custom_attributes['ended_at']}"
    puts 'Enabled features:'
    account.enabled_features.each { |feature, enabled| puts "  - #{feature}: #{enabled}" if enabled }

    # Simulate a Stripe subscription deletion webhook
    puts "\n--- Simulating Stripe subscription deletion webhook ---"

    # Create a mock event object
    mock_event = double('Stripe::Event')
    mock_data = double('data')
    mock_subscription = double('subscription')

    # Set up the mocks (simulating end-of-period cancellation)
    allow(mock_event).to receive(:type).and_return('customer.subscription.deleted')
    allow(mock_event).to receive(:data).and_return(mock_data)
    allow(mock_data).to receive(:object).and_return(mock_subscription)
    allow(mock_subscription).to receive(:customer).and_return('cus_test_123')
    allow(mock_subscription).to receive(:[]).with('ended_at').and_return(nil) # End-of-period cancellation
    allow(mock_subscription).to receive(:[]).with('canceled_at').and_return(Time.current.to_i)
    allow(mock_subscription).to receive(:[]).with('cancel_at_period_end').and_return(true)

    # Process the webhook
    service = Enterprise::Billing::HandleStripeEventService.new
    service.perform(event: mock_event)

    puts 'Webhook processed successfully!'

    # Check the results
    account.reload
    puts "\n--- AFTER Subscription Deletion ---"
    puts "Plan: #{account.custom_attributes['plan_name']}"
    puts "Status: #{account.custom_attributes['subscription_status']}"
    puts "Feature flags value: #{account.feature_flags}"
    puts "Cancel at period end: #{account.custom_attributes['cancel_at_period_end']}"
    puts "Canceled at: #{account.custom_attributes['canceled_at']}"
    puts "Ended at: #{account.custom_attributes['ended_at']}"
    puts 'Enabled features:'
    account.enabled_features.each { |feature, enabled| puts "  - #{feature}: #{enabled}" if enabled }

    # Verify the changes
    puts "\n--- Verification ---"
    if account.custom_attributes['plan_name'] == 'free'
      puts "✅ Account plan was downgraded to 'free'"
    else
      puts "❌ Account plan was NOT downgraded (still: #{account.custom_attributes['plan_name']})"
    end

    if account.custom_attributes['subscription_status'] == 'cancelled'
      puts "✅ Subscription status was set to 'cancelled' (end-of-period cancellation)"
    else
      puts "❌ Subscription status was NOT set to cancelled (still: #{account.custom_attributes['subscription_status']})"
    end

    if account.custom_attributes['cancel_at_period_end'] == true
      puts '✅ Cancel at period end flag was set correctly'
    else
      puts '❌ Cancel at period end flag was NOT set correctly'
    end

    if account.custom_attributes['canceled_at'].present?
      puts '✅ Canceled at timestamp was recorded'
    else
      puts '❌ Canceled at timestamp was NOT recorded'
    end

    if account.custom_attributes['ended_at'].nil?
      puts '✅ Ended at is nil (end-of-period cancellation)'
    else
      puts '❌ Ended at should be nil for end-of-period cancellation'
    end

    starter_features = %w[inbound_emails help_center agent_management prompts]
    disabled_features = starter_features.reject { |f| account.feature_enabled?(f) }

    if disabled_features.length == starter_features.length
      puts "✅ All starter features were disabled: #{disabled_features.join(', ')}"
    else
      enabled_features = starter_features.select { |f| account.feature_enabled?(f) }
      puts "❌ Some starter features are still enabled: #{enabled_features.join(', ')}"
    end

    puts "\n=== Testing Immediate Cancellation Scenario ==="

    # Reset account for immediate cancellation test
    account.update!(
      custom_attributes: account.custom_attributes.merge({
                                                           'plan_name' => 'professional',
                                                           'subscription_status' => 'active'
                                                         })
    )
    account.enable_features('sla', 'custom_roles')
    account.save!

    # Set up mocks for immediate cancellation
    allow(mock_subscription).to receive(:[]).with('ended_at').and_return(Time.current.to_i) # Immediate cancellation
    allow(mock_subscription).to receive(:[]).with('canceled_at').and_return(Time.current.to_i)
    allow(mock_subscription).to receive(:[]).with('cancel_at_period_end').and_return(false)

    # Process the webhook
    service.perform(event: mock_event)
    account.reload

    puts "\n--- AFTER Immediate Cancellation ---"
    puts "Status: #{account.custom_attributes['subscription_status']}"
    puts "Ended at: #{account.custom_attributes['ended_at']}"

    if account.custom_attributes['subscription_status'] == 'inactive'
      puts "✅ Subscription status was set to 'inactive' (immediate cancellation)"
    else
      puts "❌ Subscription status should be 'inactive' for immediate cancellation (got: #{account.custom_attributes['subscription_status']})"
    end

    if account.custom_attributes['ended_at'].present?
      puts '✅ Ended at timestamp was recorded for immediate cancellation'
    else
      puts '❌ Ended at timestamp should be present for immediate cancellation'
    end

    puts "\n=== Test Complete ==="
  end
end