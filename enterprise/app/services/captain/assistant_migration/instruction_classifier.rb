class Captain::AssistantMigration::InstructionClassifier < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::AssistantMigration::InstructionClassifierSchema
  CLASSIFIER_MODEL = 'gpt-5.2'.freeze
  MAX_INSTRUCTIONS_LENGTH = 20_000

  pattr_initialize [:assistant!]

  def perform
    response = make_api_call(model: CLASSIFIER_MODEL, messages: messages, schema: RESPONSE_SCHEMA)
    return error_response(response) if response[:error]

    {
      assistant: assistant_metadata,
      draft: normalized_payload(response[:message]),
      usage: response[:usage],
      request_messages: response[:request_messages]
    }
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
      needs_review: [],
      classification_notes: []
    )
  end

  def assistant_metadata # rubocop:disable Metrics/AbcSize
    {
      id: assistant.id,
      name: assistant.name,
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
