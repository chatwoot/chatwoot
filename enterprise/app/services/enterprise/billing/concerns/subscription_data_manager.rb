module Enterprise::Billing::Concerns::SubscriptionDataManager
  extend ActiveSupport::Concern

  private

  def fetch_subscription_metadata
    subscription_id = fetch_subscription_id
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    cadence_id = extract_cadence_id(subscription)
    cadence = retrieve_billing_cadence(cadence_id)
    next_billing_date = extract_attribute(cadence, :next_billing_date)

    store_next_billing_date(next_billing_date)

    {
      subscription_id: subscription_id,
      subscription: subscription,
      cadence_id: cadence_id,
      cadence: cadence,
      next_billing_date: next_billing_date
    }
  end

  def fetch_subscription_id
    subscription_id = custom_attribute('stripe_subscription_id')
    raise StandardError, 'No pricing plan subscription ID found' if subscription_id.blank?

    subscription_id
  end

  def extract_cadence_id(subscription)
    cadence_id = extract_attribute(subscription, :billing_cadence)
    raise StandardError, 'No billing cadence found in subscription' if cadence_id.blank?

    cadence_id
  end

  def store_next_billing_date(next_billing_date)
    update_custom_attributes({ 'next_billing_date' => next_billing_date })
  end
end
