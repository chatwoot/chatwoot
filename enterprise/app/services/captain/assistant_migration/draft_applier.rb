class Captain::AssistantMigration::DraftApplier
  ASSISTANT_DESCRIPTION_LIMIT = 500
  CONFIG_KEY = 'assistant_migration'.freeze
  SCENARIO_DESCRIPTION_LIMIT = 500
  ORIGINAL_VALUES_KEY = 'original_values'.freeze

  pattr_initialize [:assistant!, :draft!, { dry_run: true }]

  def perform
    changes = build_changes
    apply_changes(changes) unless dry_run

    {
      assistant_id: assistant.id,
      dry_run: dry_run,
      changes: changes
    }
  end

  private

  def build_changes
    {
      description: description_change,
      response_guidelines: array_change(:response_guidelines, response_guidelines),
      guardrails: array_change(:guardrails, guardrails),
      config: config_change
    }.compact
  end

  def apply_changes(changes)
    assistant.transaction do
      assistant.update!(assistant_update_attributes(changes)) if assistant_update_attributes(changes).present?
    end
  end

  def assistant_update_attributes(changes)
    {}.tap do |attributes|
      attributes[:description] = changes.dig(:description, :to) if changes[:description].present?
      attributes[:response_guidelines] = changes.dig(:response_guidelines, :to) if changes[:response_guidelines].present?
      attributes[:guardrails] = changes.dig(:guardrails, :to) if changes[:guardrails].present?
      attributes[:config] = changes.dig(:config, :to) if changes[:config].present?
    end
  end

  def description_change
    value = assistant_description_value
    return if value.blank? || value == assistant.description

    { from: assistant.description, to: value }
  end

  def assistant_description_value
    value = item_values(:business_product_context).join(' ').presence
    return if value.blank?

    raise ArgumentError, "Assistant description exceeds #{ASSISTANT_DESCRIPTION_LIMIT} characters" if value.length > ASSISTANT_DESCRIPTION_LIMIT

    value
  end

  def response_guidelines
    (item_values(:response_guidelines) + scenario_response_guidelines).uniq
  end

  def guardrails
    item_values(:guardrails)
  end

  def array_change(field, values)
    return if values.blank?

    current = Array(assistant.public_send(field)).map(&:to_s)
    return if current == values

    { from: current, to: values }
  end

  def config_change
    updated_config = assistant.config.deep_dup
    conversation_messages.each do |key, value|
      next if value.blank?
      next if updated_config[key].present?

      updated_config[key] = value
    end
    updated_config[CONFIG_KEY] = migration_config

    return if updated_config == assistant.config

    { from: assistant.config, to: updated_config }
  end

  def migration_config
    existing_migration_config.merge(
      ORIGINAL_VALUES_KEY => existing_original_values,
      'scenario_candidates' => staged_scenario_candidates,
      'faq_document_candidates' => normalized_faq_document_candidates,
      'needs_review' => normalized_instruction_items(:needs_review)
    )
  end

  def existing_migration_config
    config = assistant.config[CONFIG_KEY]
    config.is_a?(Hash) ? config : {}
  end

  def existing_original_values
    existing_migration_config[ORIGINAL_VALUES_KEY].presence || original_values
  end

  def original_values
    {
      'name' => assistant.name,
      'description' => assistant.description,
      'config' => original_config,
      'response_guidelines' => Array(assistant.response_guidelines),
      'guardrails' => Array(assistant.guardrails)
    }
  end

  def original_config
    assistant.config.except(CONFIG_KEY)
  end

  def conversation_messages
    messages = draft_hash.fetch(:conversation_messages, {})
    messages = messages.deep_stringify_keys

    {
      'welcome_message' => messages['welcome_message'].to_s.strip,
      'handoff_message' => messages['handoff_message'].to_s.strip,
      'resolution_message' => messages['resolution_message'].to_s.strip
    }
  end

  def staged_scenario_candidates
    scenario_candidates.map do |candidate|
      candidate.transform_keys(&:to_s)
    end
  end

  def scenario_response_guidelines
    scenario_candidates.filter_map { |candidate| candidate[:response_guideline].presence }
  end

  def scenario_tool_ids(tool_ids)
    Array(tool_ids).filter_map { |tool_id| tool_id.to_s.squish.presence }.uniq
  end

  def scenario_candidates
    Array(draft_hash[:scenario_candidates]).filter_map do |candidate|
      normalized_scenario_candidate(candidate)
    end
  end

  def normalized_scenario_candidate(candidate)
    return unless candidate.is_a?(Hash)

    candidate = candidate.deep_symbolize_keys
    normalized_candidate = {
      title: candidate[:title].to_s.squish,
      description: candidate[:description].to_s.squish.truncate(SCENARIO_DESCRIPTION_LIMIT),
      instruction: candidate[:instruction].to_s.squish,
      response_guideline: candidate[:response_guideline].to_s.squish,
      tool_ids: scenario_tool_ids(candidate[:tool_ids])
    }
    return if normalized_candidate.values_at(:title, :description, :instruction).any?(&:blank?)

    normalized_candidate
  end

  def item_values(key)
    Array(draft_hash[key]).filter_map do |item|
      item.to_s.squish.presence
    end.uniq
  end

  def normalized_instruction_items(key)
    item_values(key)
  end

  def normalized_faq_document_candidates
    Array(draft_hash[:faq_document_candidates]).map do |candidate|
      raise ArgumentError, 'FAQ document candidates must be question and answer objects' unless candidate.is_a?(Hash)

      candidate = candidate.deep_symbolize_keys
      question = candidate[:question].to_s.squish
      answer = candidate[:answer].to_s.squish
      raise ArgumentError, 'FAQ document candidates must include a question and answer' if question.blank? || answer.blank?

      { 'question' => question, 'answer' => answer }
    end.uniq
  end

  def draft_hash
    @draft_hash ||= draft.deep_symbolize_keys
  end
end
