class SystemMonitoringJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting system monitoring job"
    
    check_payment_failures
    check_integration_health
    check_usage_limits
    check_webhook_failures
    check_trial_expirations
    
    Rails.logger.info "Completed system monitoring job"
  end

  private

  def check_payment_failures
    # Check for failed payments in the last hour
    failed_payments = Subscription.joins(:payments)
                                 .where(payments: { 
                                   status: 'failed',
                                   created_at: 1.hour.ago..Time.current 
                                 })
                                 .distinct
    
    failed_payments.find_each do |subscription|
      create_alert_for_payment_failure(subscription)
    end
  end

  def check_integration_health
    # Check WhatsApp integrations
    check_whatsapp_integrations
    
    # Check email integrations
    check_email_integrations
    
    # Check other channel integrations
    check_channel_integrations
  end

  def check_whatsapp_integrations
    Channel::Whatsapp.active.find_each do |channel|
      account = channel.account
      
      # Check if we can reach WhatsApp API
      begin
        # This would be your actual WhatsApp API health check
        # For now, simulate based on recent webhook activity
        recent_activity = channel.conversations
                                .where(created_at: 2.hours.ago..Time.current)
                                .exists?
        
        unless recent_activity
          # Check if account has been trying to send messages
          failed_messages = channel.messages
                                  .where(status: 'failed')
                                  .where(created_at: 1.hour.ago..Time.current)
                                  .count
          
          if failed_messages > 5
            create_alert_for_integration_failure(account, 'whatsapp', {
              channel_id: channel.id,
              failed_messages: failed_messages,
              provider: channel.provider_config&.dig('provider_name')
            })
          end
        end
        
      rescue StandardError => e
        create_alert_for_integration_failure(account, 'whatsapp', {
          channel_id: channel.id,
          error: e.message,
          provider: channel.provider_config&.dig('provider_name')
        })
      end
    end
  end

  def check_email_integrations
    Channel::Email.active.find_each do |channel|
      account = channel.account
      
      # Check for email delivery failures
      failed_emails = channel.messages
                            .where(message_type: 'outgoing')
                            .where(status: 'failed')
                            .where(created_at: 1.hour.ago..Time.current)
                            .count
      
      if failed_emails > 3
        create_alert_for_integration_failure(account, 'email', {
          channel_id: channel.id,
          failed_emails: failed_emails,
          email: channel.email
        })
      end
    end
  end

  def check_channel_integrations
    # Check Facebook/Instagram integrations
    [Channel::FacebookPage, Channel::InstagramDirect].each do |channel_class|
      next unless defined?(channel_class)
      
      channel_class.active.find_each do |channel|
        account = channel.account
        
        # Check for API errors in recent messages
        api_errors = channel.messages
                           .where(status: 'failed')
                           .where(created_at: 1.hour.ago..Time.current)
                           .count
        
        if api_errors > 5
          create_alert_for_integration_failure(account, channel_class.name.demodulize.underscore, {
            channel_id: channel.id,
            api_errors: api_errors
          })
        end
      end
    end
  end

  def check_usage_limits
    Account.active.find_each do |account|
      plan = account.weave_core_account_plans.first
      next unless plan&.active?
      
      # Check message limits
      monthly_messages = account.conversations
                               .joins(:messages)
                               .where(messages: { created_at: 1.month.ago..Time.current })
                               .count
      
      # Define limits based on plan (these would come from your plan configuration)
      message_limits = {
        'basic' => 1000,
        'pro' => 10000,
        'premium' => 50000,
        'app' => 100000,
        'custom' => Float::INFINITY
      }
      
      limit = message_limits[plan.plan_key] || 1000
      usage_percentage = (monthly_messages.to_f / limit) * 100
      
      if usage_percentage > 90
        create_alert_for_limit_exceeded(account, 'message_limit', {
          current_usage: monthly_messages,
          limit: limit,
          percentage: usage_percentage.round(2),
          plan: plan.plan_key
        })
      end
      
      # Check agent limits
      active_agents = account.users.where(account_users: { role: 'agent' }).count
      agent_limits = {
        'basic' => 2,
        'pro' => 10,
        'premium' => 25,
        'app' => Float::INFINITY,
        'custom' => Float::INFINITY
      }
      
      agent_limit = agent_limits[plan.plan_key] || 2
      if active_agents > agent_limit
        create_alert_for_limit_exceeded(account, 'agent_limit', {
          current_agents: active_agents,
          limit: agent_limit,
          plan: plan.plan_key
        })
      end
    end
  end

  def check_webhook_failures
    # Check for webhook delivery failures
    Webhook.active.find_each do |webhook|
      account = webhook.account
      
      # This would check your webhook delivery logs
      # For now, simulate based on webhook events
      recent_failures = webhook.webhook_events
                              .where(status: 'failed')
                              .where(created_at: 1.hour.ago..Time.current)
                              .count
      
      if recent_failures > 5
        create_alert_for_webhook_failure(account, webhook, recent_failures)
      end
    end
  end

  def check_trial_expirations
    # Check for trials expiring in the next 24 hours
    expiring_trials = Weave::Core::AccountPlan.trial
                                             .where(trial_ends_at: Time.current..1.day.from_now)
    
    expiring_trials.find_each do |account_plan|
      create_alert_for_trial_expiring(account_plan.account, account_plan)
    end
    
    # Check for trials that should have been suspended but weren't
    overdue_trials = Weave::Core::AccountPlan.trial
                                            .where('trial_ends_at < ?', Time.current)
                                            .joins(:account)
                                            .where(accounts: { status: 'active' })
    
    overdue_trials.find_each do |account_plan|
      create_alert_for_overdue_trial(account_plan.account, account_plan)
    end
  end

  # Alert creation methods
  
  def create_alert_for_payment_failure(subscription)
    Weave::Core::SystemAlert.create_alert!(
      'payment_failed',
      account: subscription.account,
      severity: 'high',
      title: "Payment failure for #{subscription.account.name}",
      description: "Subscription payment failed for #{subscription.plan_key} plan",
      metadata: {
        subscription_id: subscription.id,
        plan: subscription.plan_key,
        amount: subscription.amount,
        currency: subscription.currency,
        provider: subscription.provider
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create payment failure alert: #{e.message}"
  end

  def create_alert_for_integration_failure(account, integration_type, details)
    # Don't create duplicate alerts within 1 hour
    existing_alert = Weave::Core::SystemAlert.active
                                            .where(account: account)
                                            .where(alert_type: "#{integration_type}_integration_down")
                                            .where('created_at > ?', 1.hour.ago)
                                            .exists?
    
    return if existing_alert

    Weave::Core::SystemAlert.create_alert!(
      "#{integration_type}_integration_down",
      account: account,
      severity: 'high',
      title: "#{integration_type.humanize} integration issues for #{account.name}",
      description: "#{integration_type.humanize} integration experiencing failures",
      metadata: details
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create integration failure alert: #{e.message}"
  end

  def create_alert_for_limit_exceeded(account, limit_type, details)
    # Don't create duplicate alerts within 24 hours
    existing_alert = Weave::Core::SystemAlert.active
                                            .where(account: account)
                                            .where(alert_type: limit_type)
                                            .where('created_at > ?', 24.hours.ago)
                                            .exists?
    
    return if existing_alert

    severity = details[:percentage] > 95 ? 'critical' : 'medium'

    Weave::Core::SystemAlert.create_alert!(
      limit_type,
      account: account,
      severity: severity,
      title: "Usage limit warning for #{account.name}",
      description: "Account is approaching #{limit_type.humanize.downcase} limits",
      metadata: details
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create limit exceeded alert: #{e.message}"
  end

  def create_alert_for_webhook_failure(account, webhook, failure_count)
    Weave::Core::SystemAlert.create_alert!(
      'webhook_failures',
      account: account,
      severity: 'medium',
      title: "Webhook delivery issues for #{account.name}",
      description: "Multiple webhook delivery failures detected",
      metadata: {
        webhook_id: webhook.id,
        webhook_url: webhook.target_url,
        failure_count: failure_count
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create webhook failure alert: #{e.message}"
  end

  def create_alert_for_trial_expiring(account, account_plan)
    days_remaining = ((account_plan.trial_ends_at - Time.current) / 1.day).ceil

    Weave::Core::SystemAlert.create_alert!(
      'trial_expiring',
      account: account,
      severity: 'medium',
      title: "Trial expiring soon for #{account.name}",
      description: "Trial expires in #{days_remaining} day#{'s' unless days_remaining == 1}",
      metadata: {
        plan: account_plan.plan_key,
        trial_ends_at: account_plan.trial_ends_at.iso8601,
        days_remaining: days_remaining
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create trial expiring alert: #{e.message}"
  end

  def create_alert_for_overdue_trial(account, account_plan)
    days_overdue = ((Time.current - account_plan.trial_ends_at) / 1.day).ceil

    Weave::Core::SystemAlert.create_alert!(
      'trial_overdue',
      account: account,
      severity: 'critical',
      title: "Overdue trial for #{account.name}",
      description: "Trial expired #{days_overdue} day#{'s' unless days_overdue == 1} ago but account is still active",
      metadata: {
        plan: account_plan.plan_key,
        trial_ended_at: account_plan.trial_ends_at.iso8601,
        days_overdue: days_overdue
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create overdue trial alert: #{e.message}"
  end
end