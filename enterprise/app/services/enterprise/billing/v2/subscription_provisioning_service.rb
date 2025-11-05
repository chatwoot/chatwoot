class Enterprise::Billing::V2::SubscriptionProvisioningService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::PlanProvisioningHelper
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

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
    provision_new_plan(pricing_plan_id) if pricing_plan_id.present?

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
    reset_captain_usage
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
      'pending_stripe_pricing_plan_id' => nil,
      'stripe_billing_version' => 2
    }
    attributes['stripe_pricing_plan_id'] = pricing_plan_id if pricing_plan_id.present?

    # Add plan name from catalog
    if pricing_plan_id.present?
      plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(pricing_plan_id)
      attributes['plan_name'] = plan_definition[:display_name] if plan_definition
    end

    update_custom_attributes(attributes)
  end
end
