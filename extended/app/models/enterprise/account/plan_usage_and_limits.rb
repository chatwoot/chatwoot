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
    # Return all available features for the extended community edition
    %w[
      audit_logs
      agent_bots
      campaigns
      reports
      conversation_continuity
      help_center
      sla
      macros
      automations
      captain
    ]
  end

  def captain_monthly_limit
    {
      documents: ChatwootApp.max_limit,
      responses: ChatwootApp.max_limit
    }.with_indifferent_access
  end

  private

  def get_captain_limits(type)
    total_count = ChatwootApp.max_limit

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
    { documents: ChatwootApp.max_limit, responses: ChatwootApp.max_limit }.with_indifferent_access
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
