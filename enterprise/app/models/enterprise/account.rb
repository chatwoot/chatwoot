module Enterprise::Account
  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i,
      captain: {
        documents: get_captain_limit(:documents).to_i,
        generated_responses: get_captain_limit(:responses).to_i
      }
    }
  end

  def subscribed_features
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  def captain_monthly_limit
    plan_quota = InstallationConfig.find_by(name: 'CAPTAIN_CLOUD_PLAN_LIMITS')&.value
    return 0 if plan_quota.blank?

    plan_quota = JSON.parse(plan_quota) if plan_quota.present?
    plan_quota[plan_name.downcase]
  end

  private

  def get_captain_limit(name)
    captain_monthly_limit[name.to_s]

    # In case we need to calculate the limit based on the number of agents
    # available_limit = captain_monthly_limit[name.to_s]
    # number_of_agents = custom_attributes['subscribed_quantity'] || 1

    # available_limit.to_i * number_of_agents.to_i
  end

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
end
