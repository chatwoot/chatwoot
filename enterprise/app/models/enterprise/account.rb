module Enterprise::Account
  def usage_limits
    {
      agents: agent_limits.to_i,
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
    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)
    billing_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{id}/settings/billing"
    stripe_session = Stripe::Checkout::Session.create({
                                                        line_items: [
                                                          { price: product_price.price_stripe_id, quantity: 1 }
                                                        ],
                                                        customer: stripe_customer_id,
                                                        mode: 'subscription',
                                                        allow_promotion_codes: true,
                                                        payment_method_types: ['card'],
                                                        subscription_data: { 'metadata': { id: product_price.id, account_id: id,
                                                                                           website: 'OneHash_Chat' } },
                                                        success_url: "#{billing_url}?subscription_status=success",
                                                        cancel_url: "#{billing_url}?subscription_status=cancel"
                                                      })
    if stripe_session
      stripe_session.url

    else
      Rails.logger.error("Stripe session creation failed for product price ID: #{product_price.id}")
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe API error: #{e}")
  end

  def create_subscription(product_price)
    # Removed from subscription create, because we are not offering trial on stripe plan
    # trial_end: (Date.zone.today + 5.days).to_time.to_i,
    subscription = Stripe::Subscription.create({
                                                 customer: stripe_customer_id,
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

  def agent_limits
    subscribed_quantity = custom_attributes['subscribed_quantity']
    subscribed_quantity || get_limits(:agents)
  end

  def get_limits(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    return self[:limits][limit_name.to_s] if self[:limits][limit_name.to_s].present?

    return GlobalConfig.get(config_name)[config_name] if GlobalConfig.get(config_name)[config_name].present?

    ChatwootApp.max_limit
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

  def ensure_stripe_customer_id
    stripe_customer = Stripe::Customer.create({
                                                description: name,
                                                name: name,
                                                email: billing_email,
                                                metadata: { account_id: id, created_at: created_at }
                                              })
    # rubocop:disable Rails/SkipsModelValidations
    update_attribute(:custom_attributes, custom_attributes.merge(stripe_customer_id: stripe_customer['id']))
    # rubocop:enable Rails/SkipsModelValidations
    stripe_customer['id']
  end

  def ensure_billing_email
    email = administrators.first.email
    # rubocop:disable Rails/SkipsModelValidations
    update_attribute(:custom_attributes, custom_attributes.merge(billing_email: email))
    # rubocop:enable Rails/SkipsModelValidations
    email
  end
end
