class Captain::AssistantMigration::InstructionClassifier < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::AssistantMigration::InstructionClassifierSchema
  CLASSIFIER_MODEL = 'gpt-5.2'.freeze
  MAX_INSTRUCTIONS_LENGTH = 20_000

  pattr_initialize [:assistant!]

  def perform
    classifier_response = make_api_call(model: CLASSIFIER_MODEL, messages: messages, schema: RESPONSE_SCHEMA)
    return error_response(classifier_response) if classifier_response[:error]

    generated_draft = normalized_payload(classifier_response[:message])
    auditor_response = Captain::AssistantMigration::InstructionAuditor.new(
      assistant: assistant,
      source_payload: assistant_payload,
      draft: generated_draft,
      available_additions: available_additions(generated_draft)
    ).perform
    return error_response(auditor_response) if auditor_response[:error]

    {
      assistant: assistant_metadata,
      draft: audited_payload(generated_draft, auditor_response[:message]),
      usage: combined_usage(classifier_response, auditor_response),
      request_messages: classifier_response[:request_messages]
    }
  rescue ArgumentError => e
    error_response(error: e.message, request_messages: auditor_response&.dig(:request_messages))
  end

  private

  def account
    assistant.account
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def system_prompt
    Captain::PromptRenderer.render('instruction_classifier')
  end

  def user_prompt
    JSON.pretty_generate(assistant_payload)
  end

  def assistant_payload # rubocop:disable Metrics/AbcSize
    {
      assistant_id: assistant.id,
      account_id: assistant.account_id,
      account_name: assistant.account.name,
      name: assistant.name,
      description: assistant.description,
      product_name: assistant.config['product_name'],
      instructions: truncated_instructions,
      welcome_message: assistant.config['welcome_message'],
      handoff_message: assistant.config['handoff_message'],
      resolution_message: assistant.config['resolution_message'],
      existing_response_guidelines: assistant.response_guidelines || [],
      existing_guardrails: assistant.guardrails || [],
      existing_scenarios: existing_scenarios,
      available_agent_tools: available_agent_tools,
      feature_settings: feature_settings
    }
  end

  def truncated_instructions
    instructions = assistant.config['instructions'].to_s
    return instructions if instructions.length <= MAX_INSTRUCTIONS_LENGTH

    "#{instructions.first(MAX_INSTRUCTIONS_LENGTH)}\n\n[TRUNCATED]"
  end

  def existing_scenarios
    assistant.scenarios.map do |scenario|
      {
        id: scenario.id,
        title: scenario.title,
        description: scenario.description,
        instruction: scenario.instruction,
        enabled: scenario.enabled
      }
    end
  end

  def available_agent_tools
    tools = assistant.respond_to?(:available_agent_tools) ? assistant.available_agent_tools : Captain::Assistant.built_in_agent_tools
    tools.map { |tool| tool.slice(:id, :title, :description) }
  end

  def feature_settings
    assistant.config.slice(
      'feature_faq',
      'feature_memory',
      'feature_citation',
      'feature_contact_attributes',
      'temperature'
    )
  end

  def normalized_payload(message)
    payload = message.is_a?(Hash) ? message.deep_symbolize_keys : {}
    payload.reverse_merge(
      business_product_context: [],
      response_guidelines: [],
      guardrails: [],
      scenario_candidates: [],
      conversation_messages: {},
      faq_document_candidates: [],
      needs_review: []
    )
  end

  def combined_usage(*responses)
    %w[prompt_tokens completion_tokens total_tokens].index_with do |key|
      responses.sum { |response| response.dig(:usage, key).to_i }
    end
  end

  def available_additions(draft)
    {
      response_guidelines: 20 - draft[:response_guidelines].length,
      guardrails: 20 - draft[:guardrails].length,
      scenario_candidates: 15 - draft[:scenario_candidates].length,
      faq_document_candidates: 25 - draft[:faq_document_candidates].length,
      needs_review: 20 - draft[:needs_review].length
    }
  end

  def audited_payload(generated_draft, audit_message)
    audit = audit_message.is_a?(Hash) ? audit_message.deep_symbolize_keys : {}
    generated_draft.merge(
      response_guidelines: merged_items(generated_draft, audit, :response_guidelines, 20),
      guardrails: merged_items(generated_draft, audit, :guardrails, 20),
      scenario_candidates: merged_items(generated_draft, audit, :scenario_candidates, 15),
      faq_document_candidates: merged_items(generated_draft, audit, :faq_document_candidates, 25),
      needs_review: merged_items(generated_draft, audit, :needs_review, 20)
    )
  end

  def merged_items(generated_draft, audit, key, limit)
    items = (Array(generated_draft[key]) + Array(audit[key])).uniq
    raise ArgumentError, "Audited #{key} exceeds #{limit} items" if items.length > limit

    items
  end

  def assistant_metadata # rubocop:disable Metrics/AbcSize
    {
      id: assistant.id,
      name: assistant.name,
      description: assistant.description.to_s,
      account_id: assistant.account_id,
      account_name: assistant.account.name,
      inbox_count: assistant.captain_inboxes.size,
      instruction_length: assistant.config['instructions'].to_s.length,
      original_instructions: assistant.config['instructions'].to_s,
      welcome_message: assistant.config['welcome_message'].to_s,
      handoff_message: assistant.config['handoff_message'].to_s,
      resolution_message: assistant.config['resolution_message'].to_s
    }
  end

  def error_response(response)
    {
      assistant: assistant_metadata,
      error: response[:error],
      error_code: response[:error_code],
      request_messages: response[:request_messages]
    }
  end

  def event_name
    'assistant_migration_instruction_classifier'
  end

  def captain_tasks_enabled?
    true
  end

  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
