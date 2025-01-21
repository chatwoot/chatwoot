module Enterprise::Account
  CAPTAIN_RESPONSES = 'captain_responses'.freeze
  CAPTAIN_DOCUMENTS = 'captain_documents'.freeze

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

  def increment_response_usage
    current_usage = self[:limits][CAPTAIN_RESPONSES].to_i || 0
    self[:limits][CAPTAIN_RESPONSES] = current_usage + 1
    save
  end

  def reset_response_usage
    self[:limits][CAPTAIN_RESPONSES] = 0
    save
  end

  def update_document_usage
    # this will ensure that the document count is always accurate
    self[:limits][CAPTAIN_DOCUMENTS] = captain_documents.count
    save
  end

  def subscribed_features
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  def captain_monthly_limit
    default_value = { documents: ChatwootApp.max_limit, generated_responses: ChatwootApp.max_limit }.with_indifferent_access
    return default_value if plan_name.blank?

    plan_quota = InstallationConfig.find_by(name: 'CAPTAIN_CLOUD_PLAN_LIMITS')&.value
    return default_value if plan_quota.blank?

    plan_quota = JSON.parse(plan_quota) if plan_quota.present?
    plan_quota[plan_name.downcase]
  end

  private

  def get_captain_limits(type)
    total_count = captain_monthly_limit[type.to_s].to_i

    consumed = if type == :documents
                 self[:limits][CAPTAIN_DOCUMENTS].to_i || 0
               else
                 self[:limits][CAPTAIN_RESPONSES].to_i || 0
               end

    consumed = 0 if consumed.negative?

    {
      total_count: total_count,
      current_available: (total_count - consumed).clamp(0, total_count),
      consumed: consumed
    }
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
        'agents' => { 'type': 'number' },
        'captain_responses' => { 'type': 'number' },
        'captain_documents' => { 'type': 'number' }
      },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
