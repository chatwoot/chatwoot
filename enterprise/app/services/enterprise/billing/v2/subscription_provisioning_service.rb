class Enterprise::Billing::V2::SubscriptionProvisioningService < Enterprise::Billing::V2::BaseService
  # Features for each plan tier (matching the plan hierarchy)
  STARTUP_FEATURES = %w[
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
  ].freeze

  BUSINESS_FEATURES = (STARTUP_FEATURES + %w[sla custom_roles]).freeze

  ENTERPRISE_FEATURES = (BUSINESS_FEATURES + %w[audit_logs disable_branding saml]).freeze

  def provision(subscription_id:)
    # Retrieve pricing plan subscription details from Stripe V2 API
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    # Extract details from the subscription
    pricing_plan_id = extract_pricing_plan_id(subscription)
    quantity = extract_subscription_quantity(subscription)
    # Update account with subscription details
    update_subscription_details(subscription_id, pricing_plan_id, quantity)

    # Provision the subscription: sync credits and enable features
    provision_subscription(pricing_plan_id) if pricing_plan_id.present?

    build_success_response(subscription_id, pricing_plan_id, quantity)
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Provisioning error: #{e.message}" }
  end

  private

  def build_success_response(subscription_id, pricing_plan_id, quantity)
    {
      success: true,
      subscription_id: subscription_id,
      pricing_plan_id: pricing_plan_id,
      quantity: quantity,
      message: 'Subscription provisioned successfully'
    }
  end

  def retrieve_pricing_plan_subscription(subscription_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
      {},
      stripe_api_options
    )
  end

  def extract_pricing_plan_id(subscription)
    # Extract pricing_plan from the subscription object
    pricing_plan = subscription.respond_to?(:pricing_plan) ? subscription.pricing_plan : subscription['pricing_plan']
    pricing_plan.is_a?(String) ? pricing_plan : pricing_plan&.[]('id') || pricing_plan&.dig(:id)
  end

  def extract_subscription_quantity(_subscription)
    # Get quantity from account custom_attributes (set during checkout)
    pending_quantity = account.custom_attributes['pending_subscription_quantity']
    if pending_quantity.present? && pending_quantity.to_i.positive?
      Rails.logger.info "[V2 Billing] Using quantity from custom_attributes: #{pending_quantity}"
      return pending_quantity.to_i
    end

    Rails.logger.warn '[V2 Billing] No pending_subscription_quantity found in custom_attributes, defaulting to quantity=1'
    1
  end

  def update_subscription_details(subscription_id, pricing_plan_id, quantity)
    Rails.logger.info "[V2 Billing] Updating subscription details: subscription_id=#{subscription_id}, " \
                      "pricing_plan_id=#{pricing_plan_id}, quantity=#{quantity}"

    attributes = {
      'stripe_billing_version' => 2,
      'stripe_subscription_id' => subscription_id,
      'subscribed_quantity' => quantity,
      'subscription_status' => 'active',
      'pending_subscription_quantity' => nil,
      'pending_subscription_pricing_plan' => nil
    }
    attributes['stripe_pricing_plan_id'] = pricing_plan_id if pricing_plan_id.present?

    # Add plan name from catalog
    if pricing_plan_id.present?
      plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(pricing_plan_id)
      attributes['plan_name'] = plan_definition[:display_name] if plan_definition
    end

    update_custom_attributes(attributes)
  end

  def provision_subscription(pricing_plan_id)
    # Sync monthly credits based on plan
    sync_plan_credits(pricing_plan_id)

    # Enable plan features based on plan
    enable_plan_features(pricing_plan_id)
  end

  def sync_plan_credits(pricing_plan_id)
    plan_credits = Enterprise::Billing::V2::PlanCatalog.monthly_credits_for(pricing_plan_id)
    return unless plan_credits

    Enterprise::Billing::V2::CreditManagementService
      .new(account: account)
      .sync_monthly_credits(plan_credits.to_i)
  end

  def enable_plan_features(pricing_plan_id)
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(pricing_plan_id)
    return unless plan_definition

    plan_tier = extract_plan_tier(plan_definition)
    return unless plan_tier

    features_to_enable = features_for_plan_tier(plan_tier)
    return if features_to_enable.empty?

    # Enable each feature using the account method
    account.enable_features(*features_to_enable)
  end

  def extract_plan_tier(plan_definition)
    plan_definition[:display_name].split.find { |word| %w[Startup Business Enterprise].include?(word) }
  end

  def features_for_plan_tier(plan_tier)
    case plan_tier
    when 'Startup'
      STARTUP_FEATURES
    when 'Business'
      BUSINESS_FEATURES
    when 'Enterprise'
      ENTERPRISE_FEATURES
    else
      []
    end
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
