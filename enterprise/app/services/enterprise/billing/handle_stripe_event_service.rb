class Enterprise::Billing::HandleStripeEventService
  def perform(event:)
    ensure_event_context(event)
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
    plan = find_plan(subscription['plan']['product'])
    # skipping self hosted plan events
    return if plan.blank? || account.blank?

    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: plan['name'],
        subscribed_quantity: subscription['quantity']
      }
    )
    change_plan_features
  end

  def process_subscription_deleted
    # skipping self hosted plan events
    return if account.blank?

    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end

  def change_plan_features
    if default_plan?
      disable_features
    else
      enable_features
      mark_cloud_customers
    end
  end

  def enable_features
    account.enable_features('help_center', 'campaigns', 'team_management', 'channel_twitter', 'channel_facebook', 'channel_email')
    account.save
  end

  def disable_features
    account.disable_features('help_center', 'campaigns', 'team_management', 'channel_twitter', 'channel_facebook', 'channel_email')
    account.save
  end

  def mark_cloud_customers
    emails = account.users.pluck(:email)
    contacts = Contact.where(email: emails)
    contacts.each do |contact|
      contact.add_label('cloud_customer')
      contact.update(custom_attributes: { cloud_customer: true })
    end
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

  def find_plan(plan_id)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    installation_config.value.find { |config| config['product_id'].include?(plan_id) }
  end

  def default_plan?
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config.value.first
    @account.custom_attributes['plan_name'] == default_plan['name']
  end
end
