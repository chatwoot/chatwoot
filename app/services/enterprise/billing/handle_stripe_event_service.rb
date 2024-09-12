class Enterprise::Billing::HandleStripeEventService
  def perform(event:)
    ensure_event_context(event)
    case @event.type
    when 'customer.subscription.created'
      process_subscription_updated
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
    plan = find_plan(subscription['plan']['id'])
    return if plan.blank? || account.blank?

    update_account(subscription, plan)
    update_limits
  end

  def update_account(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object
    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        stripe_subscription_id: subscription['id'],
        plan_name: plan,
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
  end

  def update_limits
    account.update_usage_limits
  end

  def process_subscription_deleted
    return if account.blank?

    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end

  def ensure_event_context(event)
    @event = event
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def find_plan(price_id)
    subscription_plan = SubscriptionPlan.find_by(stripe_price_id: price_id)
    return subscription_plan.plan_name if subscription_plan.present?
  end
end
