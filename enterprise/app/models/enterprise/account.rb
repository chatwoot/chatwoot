module Enterprise::Account
  ACCOUNT_RESPONSES_LIMIT = 'ACCOUNT_RESPONSES_LIMIT'.freeze

  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i,
      captain: {
        documents: get_captain_limits(:documents),
        generated_responses: get_captain_limits(:responses)
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

  def get_captain_limits(type)
    total_count = captain_monthly_limit[type].to_i

    consumed = if type == :documents
                 captain_documents.available.count
               else
                 self[:limits][ACCOUNT_RESPONSES_LIMIT] || 0
               end

    {
      total_count: total_count,
      current_available: [total_count - consumed, 0].max,
      consumed: consumed
    }
  end

  def increment_response_usage
    config_name = ACCOUNT_RESPONSES_LIMIT
    self[:limits][config_name] = 0 if self[:limits][config_name].blank?
    self[:limits][config_name] = self[:limits][config_name].to_i + 1
    save
  end

  def reset_response_usage
    config_name = ACCOUNT_RESPONSES_LIMIT
    self[:limits][config_name] = 0
    save
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
