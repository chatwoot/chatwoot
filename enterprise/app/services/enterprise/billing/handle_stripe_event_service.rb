class Enterprise::Billing::HandleStripeEventService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  # Plan hierarchy: Hacker (default) -> Startups -> Business -> Enterprise
  # Each higher tier includes all features from the lower tiers

  # Basic features available starting with the Startups plan
  STARTUP_PLAN_FEATURES = %w[
    inbound_emails
    help_center
    campaigns
    team_management
    channel_twitter
    channel_facebook
    channel_email
    channel_instagram
    captain_integration
  ].freeze

  # Additional features available starting with the Business plan
  BUSINESS_PLAN_FEATURES = %w[sla custom_roles].freeze

  # Additional features available only in the Enterprise plan
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding].freeze

  def perform(event:)
    @event = event

    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def process_subscription_updated
    plan = find_plan(subscription['plan']['product']) if subscription['plan'].present?

    # skipping self hosted plan events
    return if plan.blank? || account.blank?

    update_account_attributes(subscription, plan)
    update_plan_features
    reset_captain_usage
  end

  def update_account_attributes(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object
    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: plan['name'],
        subscribed_quantity: subscription['quantity'],
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
  end

  def process_subscription_deleted
    # skipping self hosted plan events
    return if account.blank?

    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end

  def update_plan_features
    if default_plan?
      disable_all_premium_features
    else
      enable_features_for_current_plan
    end

    # Enable any manually managed features configured in internal_attributes
    enable_account_manually_managed_features

    account.save!
  end

  def disable_all_premium_features
    # Disable all features (for default Hacker plan)
    account.disable_features(*STARTUP_PLAN_FEATURES)
    account.disable_features(*BUSINESS_PLAN_FEATURES)
    account.disable_features(*ENTERPRISE_PLAN_FEATURES)
  end

  def enable_features_for_current_plan
    # First disable all premium features to handle downgrades
    disable_all_premium_features

    # Then enable features based on the current plan
    enable_plan_specific_features
  end

  def reset_captain_usage
    account.reset_response_usage
  end

  def enable_plan_specific_features
    plan_name = account.custom_attributes['plan_name']
    return if plan_name.blank?

    # Enable features based on plan hierarchy
    case plan_name
    when 'Startups'
      # Startups plan gets the basic features
      account.enable_features(*STARTUP_PLAN_FEATURES)
    when 'Business'
      # Business plan gets Startups features + Business features
      account.enable_features(*STARTUP_PLAN_FEATURES)
      account.enable_features(*BUSINESS_PLAN_FEATURES)
    when 'Enterprise'
      # Enterprise plan gets all features
      account.enable_features(*STARTUP_PLAN_FEATURES)
      account.enable_features(*BUSINESS_PLAN_FEATURES)
      account.enable_features(*ENTERPRISE_PLAN_FEATURES)
    end
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def find_plan(plan_id)
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    cloud_plans.find { |config| config['product_id'].include?(plan_id) }
  end

  def default_plan?
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    default_plan = cloud_plans.first || {}
    account.custom_attributes['plan_name'] == default_plan['name']
  end

  def enable_account_manually_managed_features
    # Get manually managed features from internal attributes using the service
    service = Internal::Accounts::InternalAttributesService.new(account)
    features = service.manually_managed_features

    # Enable each feature
    account.enable_features(*features) if features.present?
  end
end
