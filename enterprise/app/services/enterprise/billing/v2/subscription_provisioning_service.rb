class Enterprise::Billing::V2::SubscriptionProvisioningService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::PlanProvisioningHelper
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  def provision(subscription_id:)
    process_subscription(subscription_id)
  end

  def refresh
    return if stripe_subscription_id.blank?

    process_subscription(stripe_subscription_id)
  end

  private

  def process_subscription(subscription_id)
    # Retrieve pricing plan subscription details from Stripe V2 API
    subscription = retrieve_pricing_plan_subscription(subscription_id)

    # Check if subscription is canceled
    if servicing_status(subscription) == 'canceled'
      cancel_subscription
      reset_captain_usage
      return { pricing_plan_id: nil, quantity: nil }
    end

    # Extract details from the subscription
    pricing_plan_id = extract_pricing_plan_id(subscription)
    quantity = extract_subscription_quantity(subscription)
    billing_cadence = extract_billing_cadence(subscription)

    # Update account with subscription details
    update_subscription_details(subscription_id, pricing_plan_id, quantity, billing_cadence)

    # Provision the subscription: sync credits and enable features
    provision_new_plan(pricing_plan_id) if pricing_plan_id.present?

    # Reset usage for the new billing cycle
    reset_captain_usage

    { pricing_plan_id: pricing_plan_id, quantity: quantity }
  end

  def servicing_status(subscription_plan)
    extract_attribute(subscription_plan, :servicing_status)
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
    extract_attribute(subscription, :pricing_plan)
  end

  def extract_billing_cadence(subscription)
    extract_attribute(subscription, :billing_cadence)
  end

  def extract_subscription_quantity(_subscription)
    # Get quantity from account custom_attributes (set during checkout)
    pending_quantity = custom_attribute('pending_subscription_quantity')
    return pending_quantity.to_i if pending_quantity.present? && pending_quantity.to_i.positive?

    return subscribed_quantity if subscribed_quantity.positive?

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
