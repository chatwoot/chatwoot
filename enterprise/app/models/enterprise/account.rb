module Enterprise::Account
  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i
    }
  end

  def subscribed_features
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  private

  def plan_name
    custom_attributes['plan_name']
  end

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
