class Enterprise::Billing::CancelCloudSubscriptionsService
  pattr_initialize [:account!]

  def perform
    return if stripe_customer_id.blank?
    return unless ChatwootApp.chatwoot_cloud?

    subscriptions.each do |subscription|
      next if subscription.cancel_at_period_end

      Stripe::Subscription.update(subscription.id, cancel_at_period_end: true)
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
