class Captain::AssistantMigration::DraftApplier
  pattr_initialize [:assistant!, :draft!, { dry_run: true, apply_scenarios: false }]

  def perform
    changes = build_changes
    apply_changes(changes) unless dry_run

    {
      assistant_id: assistant.id,
      dry_run: dry_run,
      apply_scenarios: apply_scenarios,
      changes: changes
    }
  end

  private

  def build_changes
    {
      description: description_change,
      response_guidelines: array_change(:response_guidelines, response_guidelines),
      guardrails: array_change(:guardrails, guardrails),
      config: config_change,
      scenarios: scenario_changes
    }.compact
  end

  def apply_changes(changes)
    assistant.transaction do
      assistant.update!(assistant_update_attributes(changes)) if assistant_update_attributes(changes).present?
      apply_scenario_changes(changes[:scenarios]) if apply_scenarios && changes[:scenarios].present?
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

  def apply_scenario_changes(changes)
    changes.each do |change|
      scenario = assistant.scenarios.find_or_initialize_by(title: change[:title])
      scenario.assign_attributes(
        account: assistant.account,
        description: change[:description],
        instruction: change[:instruction],
        enabled: true,
        tools: change[:tool_ids] || []
      )
      scenario.save!
    end
  end

  def description_change
    value = item_values(:business_product_context).join("\n").presence
    return if value.blank? || value == assistant.description

    { from: assistant.description, to: value }
  end

  def response_guidelines
    item_values(:response_guidelines)
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

    return if updated_config == assistant.config

    { from: assistant.config, to: updated_config }
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

  def scenario_changes
    return [] unless apply_scenarios

    structured_scenario_changes.presence || legacy_scenario_changes
  end

  def structured_scenario_changes
    Array(draft_hash[:scenario_candidates]).filter_map do |candidate|
      next unless candidate.is_a?(Hash)

      candidate = candidate.deep_symbolize_keys
      instruction = candidate[:instruction].to_s.squish
      title = candidate[:title].to_s.squish
      description = candidate[:description].to_s.squish
      next if title.blank? || description.blank? || instruction.blank?

      {
        title: title.truncate(80),
        description: description.truncate(300),
        instruction: instruction,
        tool_ids: scenario_tool_ids(candidate[:tool_ids])
      }
    end
  end

  def legacy_scenario_changes
    item_values(:scenarios_procedures).map.with_index(1) do |instruction, index|
      {
        title: legacy_scenario_title(instruction, index),
        description: instruction.truncate(200),
        instruction: instruction,
        tool_ids: []
      }
    end
  end

  def scenario_tool_ids(tool_ids)
    Array(tool_ids).filter_map { |tool_id| tool_id.to_s.squish.presence }.uniq
  end

  def legacy_scenario_title(instruction, index)
    title = instruction.to_s.split(/[.\n]/).first.to_s.squish
    title = "Migrated scenario #{index}" if title.blank?
    title.truncate(80)
  end

  def item_values(key)
    Array(draft_hash[key]).filter_map do |item|
      value = if item.is_a?(Hash)
                item.deep_symbolize_keys[:value]
              else
                item
              end

      value.to_s.squish.presence
    end.uniq
  end

  def draft_hash
    @draft_hash ||= draft.deep_symbolize_keys
  end
end
