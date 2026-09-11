module Enterprise::Account::PlanUsageAndLimits # rubocop:disable Metrics/ModuleLength
  CAPTAIN_RESPONSES = 'captain_responses'.freeze
  CAPTAIN_DOCUMENTS = 'captain_documents'.freeze
  CAPTAIN_RESPONSES_USAGE = 'captain_responses_usage'.freeze
  CAPTAIN_RESPONSE_RESERVATIONS = 'captain_response_reservations'.freeze
  CAPTAIN_RESPONSE_RESERVATION_TTL = 1.hour
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
    return unless ChatwootApp.chatwoot_cloud?

    increment_custom_attribute(CAPTAIN_RESPONSES_USAGE)
  end

  # rubocop:disable Rails/SkipsModelValidations
  def reserve_response_usage
    response_limit = captain_monthly_limit[:responses].to_i
    return false unless response_limit.positive?

    reservation_id = SecureRandom.uuid
    with_lock do
      reservations = active_response_reservations
      next false if custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i + reservations.size >= response_limit

      reservations[reservation_id] = CAPTAIN_RESPONSE_RESERVATION_TTL.from_now.to_i
      update_custom_attribute(CAPTAIN_RESPONSE_RESERVATIONS, reservations)
      reservation_id
    end
  end

  def renew_response_usage(reservation_id)
    with_lock do
      reservations = response_reservations
      next false unless reservations.key?(reservation_id)

      reservations[reservation_id] = CAPTAIN_RESPONSE_RESERVATION_TTL.from_now.to_i
      update_custom_attribute(CAPTAIN_RESPONSE_RESERVATIONS, reservations)
      true
    end
  end

  def release_response_usage(reservation_id)
    with_lock do
      reservations = response_reservations
      released = reservations.delete(reservation_id).present?
      reservations = active_response_reservations(reservations)
      update_custom_attribute(CAPTAIN_RESPONSE_RESERVATIONS, reservations)
      released
    end
  end

  def commit_response_usage(reservation_id)
    with_lock do
      reservations = response_reservations
      next false unless reservations.delete(reservation_id)

      Account.where(id: id).update_all(response_reservation_commit(reservations))
      custom_attributes[CAPTAIN_RESPONSE_RESERVATIONS] = reservations
      custom_attributes[CAPTAIN_RESPONSES_USAGE] = custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i + 1
      clear_attribute_changes([:custom_attributes])
      true
    end
  end

  def reset_response_usage
    update_custom_attribute(CAPTAIN_RESPONSES_USAGE, 0)
  end

  def update_document_usage
    update_custom_attribute(CAPTAIN_DOCUMENTS_USAGE, captain_documents.count)
  end

  def email_transcript_enabled?
    return current_billing_plan.present? if shopify_billing?

    default_plan = Enterprise::Billing::PlanConfiguration.default_plan
    return true if default_plan.blank?

    plan_name.present? && plan_name != default_plan['name']
  end

  def email_rate_limit
    account_limit || plan_email_limit || global_limit || default_limit
  end

  def subscribed_features
    return current_billing_plan&.fetch('features', []) || [] if shopify_billing?

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
    reserved = type == :responses ? active_response_reservations.size : 0

    {
      total_count: total_count,
      current_available: (total_count - consumed - reserved).clamp(0, total_count),
      consumed: consumed
    }
  end

  def plan_email_limit
    return shopify_plan_limits.fetch('emails', 0) if shopify_billing?

    base_limit = plan_base_email_limit
    return nil if base_limit.nil?
    return base_limit if free_plan?

    base_limit * [agent_limits.to_i, 1].max
  end

  def plan_base_email_limit
    config = InstallationConfig.find_by(name: 'ACCOUNT_EMAILS_PLAN_LIMITS')&.value
    return nil if config.blank? || plan_name.blank?

    parsed = config.is_a?(String) ? JSON.parse(config) : config
    parsed[plan_name.downcase]&.to_i
  rescue StandardError
    nil
  end

  def free_plan?
    return false if shopify_billing?

    default_plan = Enterprise::Billing::PlanConfiguration.default_plan
    default_plan.present? && plan_name&.downcase == default_plan['name']&.downcase
  end

  def default_captain_limits
    shopify_billing? ? shopify_captain_limits : stripe_captain_limits
  end

  def stripe_captain_limits
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

  def shopify_captain_limits
    {
      documents: shopify_plan_limits.fetch('captain_documents', 0),
      responses: shopify_plan_limits.fetch('captain_responses', 0)
    }.with_indifferent_access
  end

  def plan_name
    custom_attributes['plan_name']
  end

  def agent_limits
    subscribed_quantity = custom_attributes['subscribed_quantity'] unless shopify_billing?
    subscribed_quantity || get_limits(:agents)
  end

  def get_limits(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    return self[:limits][limit_name.to_s] if self[:limits][limit_name.to_s].present?
    return shopify_plan_limits.fetch(limit_name.to_s, 0) if shopify_billing?

    return GlobalConfig.get(config_name)[config_name] if GlobalConfig.get(config_name)[config_name].present?

    ChatwootApp.max_limit
  end

  def shopify_billing?
    billing_provider == 'shopify'
  end

  def current_billing_plan
    Enterprise::Billing::PlanConfiguration.current_plan(self)
  end

  def shopify_plan_limits
    current_billing_plan&.fetch('limits', {}) || {}
  end

  # Atomic jsonb_set to avoid clobbering concurrent writes to other custom_attributes keys.
  # Goes through Account relation (rather than raw connection) so shard routing is respected.
  def update_custom_attribute(key, value)
    Account.where(id: id).update_all([
                                       "custom_attributes = jsonb_set(COALESCE(custom_attributes, '{}'), ARRAY[:key], :value::jsonb)",
                                       { key: key, value: value.to_json }
                                     ])
    custom_attributes[key] = value
    clear_attribute_changes([:custom_attributes])
  end

  def increment_custom_attribute(key)
    Account.where(id: id).update_all([
                                       "custom_attributes = jsonb_set(COALESCE(custom_attributes, '{}'), ARRAY[:key], " \
                                       '(COALESCE((custom_attributes ->> :key)::int, 0) + 1)::text::jsonb)',
                                       { key: key }
                                     ])
    custom_attributes[key] = custom_attributes[key].to_i + 1
    clear_attribute_changes([:custom_attributes])
  end

  def active_response_reservations(reservations = response_reservations)
    reservations.select { |_reservation_id, expires_at| expires_at.to_i > Time.current.to_i }
  end

  def response_reservations
    reservations = custom_attributes[CAPTAIN_RESPONSE_RESERVATIONS]
    return {} unless reservations.is_a?(Hash)

    reservations.dup
  end

  def response_reservation_commit(reservations)
    [
      "custom_attributes = jsonb_set(jsonb_set(COALESCE(custom_attributes, '{}'), ARRAY[:usage_key], " \
      '(COALESCE((custom_attributes ->> :usage_key)::int, 0) + 1)::text::jsonb), ARRAY[:reservations_key], ' \
      ':reservations::jsonb)',
      {
        usage_key: CAPTAIN_RESPONSES_USAGE,
        reservations_key: CAPTAIN_RESPONSE_RESERVATIONS,
        reservations: reservations.to_json
      }
    ]
  end
  # rubocop:enable Rails/SkipsModelValidations

  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    limit_schema = {
      'type' => 'object',
      'properties' => {
        'inboxes' => { 'type': 'number' },
        'agents' => { 'type': 'number' },
        'captain_responses' => { 'type': 'number' },
        'captain_documents' => { 'type': 'number' },
        'emails' => { 'type': 'number' }
      },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
