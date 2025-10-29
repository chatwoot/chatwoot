class Enterprise::Billing::V2::SubscriptionProvisioningService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  def provision(subscription_id:)
    # Retrieve pricing plan subscription details from Stripe V2 API
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    # Extract details from the subscription
    pricing_plan_id = extract_pricing_plan_id(subscription)
    quantity = extract_subscription_quantity(subscription)
    billing_cadence = extract_billing_cadence(subscription)
    # Update account with subscription details
    update_subscription_details(subscription_id, pricing_plan_id, quantity, billing_cadence)

    # Provision the subscription: sync credits and enable features
    provision_subscription(pricing_plan_id) if pricing_plan_id.present?

    build_success_response(subscription_id, pricing_plan_id, quantity)
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  end

  def refresh
    subscription_id = account.custom_attributes['stripe_subscription_id']
    return if subscription_id.blank?

    subscription_plan = retrieve_pricing_plan_subscription(subscription_id)
    servicing_status = servicing_status(subscription_plan)
    pricing_plan_id = extract_pricing_plan_id(subscription_plan)
    if servicing_status == 'canceled'
      cancel_subscription
    else
      quantity = account.custom_attributes['subscribed_quantity']
      billing_cadence = extract_billing_cadence(subscription_plan)
      update_subscription_details(subscription_id, pricing_plan_id, quantity, billing_cadence)
    end
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

  def servicing_status(subscription_plan)
    subscription_plan.respond_to?(:servicing_status) ? subscription_plan.servicing_status : subscription_plan['servicing_status']
  end

  def cancel_subscription
    hacker_plan_config = InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID')
    pricing_plan_id = hacker_plan_config.value

    # Update subscription status and plan details
    attributes = {
      'plan_name': 'Hacker',
      'stripe_pricing_plan_id': pricing_plan_id,
      'subscribed_quantity': 2,
      'stripe_subscription_id': nil,
      'billing_cadence': nil,
      'subscription_status': 'canceled'
    }
    update_custom_attributes(attributes)

    # Sync credits for Hacker plan (0 credits)
    sync_plan_credits(pricing_plan_id)

    # Disable all premium features and save
    disable_all_premium_features
    account.save!

    # Reset captain usage
    reset_captain_usage
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
    subscription.respond_to?(:pricing_plan) ? subscription.pricing_plan : subscription['pricing_plan']
  end

  def extract_billing_cadence(subscription)
    subscription.respond_to?(:billing_cadence) ? subscription.billing_cadence : subscription['billing_cadence']
  end

  def extract_subscription_quantity(_subscription)
    # Get quantity from account custom_attributes (set during checkout)
    pending_quantity = account.custom_attributes['pending_subscription_quantity']
    if pending_quantity.present? && pending_quantity.to_i.positive?
      Rails.logger.info "[V2 Billing] Using quantity from custom_attributes: #{pending_quantity}"
      return pending_quantity.to_i
    end
    subscribed_quantity = account.custom_attributes['subscribed_quantity']
    if subscribed_quantity.present? && subscribed_quantity.to_i.positive?
      Rails.logger.info "[V2 Billing] Using quantity from custom_attributes: #{subscribed_quantity}"
      return subscribed_quantity.to_i
    end
    1
  end

  def update_subscription_details(subscription_id, pricing_plan_id, quantity, billing_cadence)
    Rails.logger.info "[V2 Billing] Updating subscription details: subscription_id=#{subscription_id}, " \
                      "pricing_plan_id=#{pricing_plan_id}, quantity=#{quantity}"

    attributes = {
      'stripe_subscription_id' => subscription_id,
      'subscribed_quantity' => quantity,
      'subscription_status' => 'active',
      'pending_subscription_quantity' => nil,
      'pending_subscription_pricing_plan' => nil,
      'billing_cadence' => billing_cadence,
      'next_billing_date' => nil,
      'pending_stripe_pricing_plan_id' => nil
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

    # Extract plan name and enable features using PlanFeatureManager
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(pricing_plan_id)
    if plan_definition
      plan_name = extract_plan_name(plan_definition)
      enable_plan_specific_features(plan_name) if plan_name.present?
    end

    # Reset captain usage after provisioning
    reset_captain_usage
  end

  def sync_plan_credits(pricing_plan_id)
    plan_credits = Enterprise::Billing::V2::PlanCatalog.monthly_credits_for(pricing_plan_id)

    Enterprise::Billing::V2::CreditManagementService
      .new(account: account)
      .sync_monthly_credits(plan_credits.to_i)
  end

  def extract_plan_name(plan_definition)
    # Extract plan name like "Startup", "Business", or "Enterprise" from display_name
    # e.g., "Chatwoot Startup" -> "Startup"
    plan_definition[:display_name].split.find { |word| %w[Startup Startups Business Enterprise].include?(word) }
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
