module Enterprise::Account::PlanUsageAndLimits
  CAPTAIN_RESPONSES = 'captain_responses'.freeze
  CAPTAIN_DOCUMENTS = 'captain_documents'.freeze
  CAPTAIN_RESPONSES_USAGE = 'captain_responses_usage'.freeze
  CAPTAIN_DOCUMENTS_USAGE = 'captain_documents_usage'.freeze

  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i,
      captain: {
        documents: get_captain_limits(:documents),
        responses: get_captain_limits(:responses)
      }
    }
  end

  def increment_response_usage
    current_usage = custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i || 0
    custom_attributes[CAPTAIN_RESPONSES_USAGE] = current_usage + 1
    save
  end

  def reset_response_usage
    custom_attributes[CAPTAIN_RESPONSES_USAGE] = 0
    save
  end

  def update_document_usage
    # this will ensure that the document count is always accurate
    custom_attributes[CAPTAIN_DOCUMENTS_USAGE] = captain_documents.count
    save
  end

  def subscribed_features
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  def captain_monthly_limit
    default_limits = default_captain_limits

    {
      documents: self[:limits][CAPTAIN_DOCUMENTS] || default_limits['documents'],
      responses: self[:limits][CAPTAIN_RESPONSES] || default_limits['responses']
    }.with_indifferent_access
  end

  private

  def get_captain_limits(type)
    total_count = captain_monthly_limit[type.to_s].to_i

    consumed = if type == :documents
                 custom_attributes[CAPTAIN_DOCUMENTS_USAGE].to_i || 0
               else
                 custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i || 0
               end

    consumed = 0 if consumed.negative?

    {
      total_count: total_count,
      current_available: (total_count - consumed).clamp(0, total_count),
      consumed: consumed
    }
  end

  def default_captain_limits
    max_limits = { documents: ChatwootApp.max_limit, responses: ChatwootApp.max_limit }.with_indifferent_access
    zero_limits = { documents: 0, responses: 0 }.with_indifferent_access
    plan_quota = InstallationConfig.find_by(name: 'CAPTAIN_CLOUD_PLAN_LIMITS')&.value

    # If there are no limits configured, we allow max usage
    return max_limits if plan_quota.blank?

    # if there is plan_quota configred, but plan_name is not present, we return zero limits
    return zero_limits if plan_name.blank?

    begin
      # Now we parse the plan_quota and return the limits for the plan name
      # but if there's no plan_name present in the plan_quota, we return zero limits
      plan_quota = JSON.parse(plan_quota) if plan_quota.present?
      plan_quota[plan_name.downcase] || zero_limits
    rescue StandardError
      # if there's any error in parsing the plan_quota, we return max limits
      # this is to ensure that we don't block the user from using the product
      max_limits
    end
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
