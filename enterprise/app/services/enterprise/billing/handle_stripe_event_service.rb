class Enterprise::Billing::HandleStripeEventService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  CAPTAIN_CLOUD_PLAN_LIMITS = 'CAPTAIN_CLOUD_PLAN_LIMITS'.freeze

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
    advanced_search_indexing
    advanced_search
    linear_integration
  ].freeze

  # Additional features available starting with the Business plan
  BUSINESS_PLAN_FEATURES = %w[sla custom_roles csat_review_notes conversation_required_attributes advanced_assignment].freeze

  # Additional features available only in the Enterprise plan
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding saml].freeze

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

    previous_usage = capture_previous_usage
    update_account_attributes(subscription, plan)
    update_plan_features

    if billing_period_renewed?
      ActiveRecord::Base.transaction do
        handle_subscription_credits(plan, previous_usage)
        account.reset_response_usage
      end
    elsif plan_changed?
      handle_plan_change_credits(plan, previous_usage)
    end
  end

  def capture_previous_usage
    { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: current_plan_credits[:responses] }
  end

  def current_plan_credits
    plan_name = account.custom_attributes['plan_name']
    return { responses: 0, documents: 0 } if plan_name.blank?

    get_plan_credits(plan_name)
  end

  def update_account_attributes(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object
    account.update(
      custom_attributes: account.custom_attributes.merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_price_id' => subscription['plan']['id'],
        'stripe_product_id' => subscription['plan']['product'],
        'plan_name' => plan['name'],
        'subscribed_quantity' => subscription['quantity'],
        'subscription_status' => subscription['status'],
        'subscription_ends_on' => Time.zone.at(subscription['current_period_end'])
      )
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

  def handle_subscription_credits(plan, previous_usage)
    current_limits = account.limits || {}

    current_credits = current_limits['captain_responses'].to_i
    new_plan_credits = get_plan_credits(plan['name'])[:responses]

    consumed_topup_credits = [previous_usage[:responses] - previous_usage[:monthly], 0].max
    updated_credits = current_credits - consumed_topup_credits - previous_usage[:monthly] + new_plan_credits

    Rails.logger.info("Updating subscription credits for account #{account.id}: #{current_credits} -> #{updated_credits}")
    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def handle_plan_change_credits(new_plan, previous_usage)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    previous_plan_credits = previous_usage[:monthly]
    new_plan_credits = get_plan_credits(new_plan['name'])[:responses]

    updated_credits = current_credits - previous_plan_credits + new_plan_credits

    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def get_plan_credits(plan_name)
    config = InstallationConfig.find_by(name: CAPTAIN_CLOUD_PLAN_LIMITS).value
    config = JSON.parse(config) if config.is_a?(String)
    config[plan_name.downcase]&.symbolize_keys
  end

  def enable_plan_specific_features
    plan_name = account.custom_attributes['plan_name']
    return if plan_name.blank?

    case plan_name
    when 'Startups' then account.enable_features(*STARTUP_PLAN_FEATURES)
    when 'Business'
      account.enable_features(*STARTUP_PLAN_FEATURES, *BUSINESS_PLAN_FEATURES)
    when 'Enterprise'
      account.enable_features(*STARTUP_PLAN_FEATURES, *BUSINESS_PLAN_FEATURES, *ENTERPRISE_PLAN_FEATURES)
    end
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def previous_attributes
    @previous_attributes ||= JSON.parse((@event.data.previous_attributes || {}).to_json)
  end

  def plan_changed?
    return false if previous_attributes['plan'].blank?

    previous_plan_id = previous_attributes.dig('plan', 'id')
    current_plan_id = subscription['plan']['id']

    previous_plan_id != current_plan_id
  end

  def billing_period_renewed?
    return false if previous_attributes['current_period_start'].blank?

    previous_attributes['current_period_start'] != subscription['current_period_start']
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
