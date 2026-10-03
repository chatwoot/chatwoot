class Enterprise::Billing::CancelCloudSubscriptionsService
  include BillingHelper

  pattr_initialize [:account!]

  def perform
    return if stripe_customer_id.blank?
    return unless ChatwootApp.chatwoot_cloud?

    subscriptions.each do |subscription|
      next if subscription_cancels_on(subscription).present?

      # cancel_at_period_end is deprecated; an explicit timestamp works on every billing mode.
      Stripe::Subscription.update(subscription.id, cancel_at: subscription_period_end(subscription))
    end
  end

  private

  def subscriptions
    Stripe::Subscription.list(customer: stripe_customer_id, status: 'active', limit: 100).data
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
