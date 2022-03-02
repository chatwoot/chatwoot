module Enterprise::Account
  def usage_limits
    {
      agents: get_limits(:agents).to_i,
      inboxes: get_limits(:inboxes).to_i
    }
  end

  def stripe_customer_id
    custom_attributes['stripe_customer_id'] || ensure_stripe_customer_id
  end

  def billing_email
    custom_attributes['billing_email'] || ensure_billing_email
  end

  def create_checkout_link(product_price)
    billing_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{id}/settings/billing"
    stripe_session = Stripe::Checkout::Session.create({
      success_url: "#{billing_url}?subscription_status=success" ,
      cancel_url: "#{billing_url}?subscription_status=cancel",
      line_items: [
        { price: product_price.price_stripe_id, quantity: account_users.count },
      ],
      customer: stripe_customer_id,
      mode: 'subscription'
    })
    stripe_session.url
  end

  def create_subscription(product_price)
    subscription = Stripe::Subscription.create({
      customer: stripe_customer_id,
      trial_end: (Date.today+5.days).to_time.to_i,
      items: [
        {
          price: product_price.price_stripe_id,
          quantity: account_users.count
        }
      ]
    })

    account_billing_subscriptions.create(subscription_stripe_id: subscription.id, billing_product_price: product_price)
  end

  private

  def ensure_stripe_customer_id
    stripe_customer = Stripe::Customer.create({
      description: name,
      name: name,
      email: billing_email, 
      metadata: {account_id: id, created_at: created_at}
    })

    update_attribute(:custom_attributes, custom_attributes.merge(stripe_customer_id: stripe_customer['id']))
    stripe_customer['id']
  end

  def ensure_billing_email
    email = administrators.first.email
    update_attribute(:custom_attributes, custom_attributes.merge(billing_email: email))
    email
  end

  def get_limits(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    self[:limits][limit_name.to_s] || GlobalConfig.get(config_name)[config_name] || ChatwootApp.max_limit
  end

  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    limit_schema = {
      'type' => 'object',
      'properties' => {
        'inboxes' => { 'type': 'number' },
        'agents' => { 'type': 'number' }
      },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
