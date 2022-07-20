class Enterprise::Billing::HandleStripeEventService
  def perform(event:)
    ensure_event_context(event)
    case @event.type
    when 'customer.subscription.updated'
      plan = find_plan(subscription['plan']['product'])
      account.update(
        custom_attributes: {
          stripe_customer_id: subscription.customer,
          stripe_price_id: subscription['plan']['id'],
          stripe_product_id: subscription['plan']['product'],
          plan_name: plan['name'],
          subscribed_quantity: subscription['quantity']
        }
      )
    when 'customer.subscription.deleted'
      Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def ensure_event_context(event)
    @event = event
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def find_plan(plan_id)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    installation_config.value.find { |config| config['product_id'].include?(plan_id) }
  end
end
