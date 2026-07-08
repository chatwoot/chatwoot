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
    <<~PROMPT
      You are migrating Captain assistant instructions into a structured configuration.

      Classify the existing assistant instructions into these sections:
      1. Business/Product Context
      2. Response Guidelines
      3. Guardrails
      4. Scenario Candidates
      5. Conversation Messages
      6. FAQs/Documents Candidates
      7. Needs Review

      Rules:
      - Preserve behavior as closely as possible.
      - Do not duplicate the same content across sections.
      - Return clean migrated values only. Do not include source excerpts, source labels, citations, or "Source:" text in any migrated field.
      - Do not rewrite customer-facing message copy unless necessary to classify an exact copy from instructions.
      - Existing welcome_message, handoff_message, and resolution_message config values are provided separately.
      - Treat welcome_message, handoff_message, and resolution_message as Captain conversation message config fields.
      - Extract exact welcome, handoff, or resolution message copy from instructions into conversation_messages when present.
      - Do not copy message values from existing config into conversation_messages.
      - Do not decide whether existing config values should be overwritten. Migration code handles applying extracted
        conversation_messages only when the corresponding config value is blank.
      - In the current architecture, a scenario becomes a specialized sub-agent with its own title, description,
        instructions, and optional tools.
      - Only create scenario candidates for distinct user-intent workflows that should be routed to a specialized agent.
        A candidate must be narrow enough to become a named specialist assistant with domain-specific handling instructions.
      - Good scenario candidates include multi-step intake workflows, qualification flows, specialized troubleshooting
        workflows, or tool-use procedures for a specific user intent.
      - Do not create scenario candidates for global escalation rules, generic handoff policy, missing-information
        behavior, source-boundary rules, refusal rules, tone, formatting, answer length, or one-step fallback behavior.
      - Do not create scenario candidates whose main purpose is to escalate or hand off. "Identify the trigger, avoid
        guessing, tell the user support will review, and hand off" is a guardrail/handoff boundary, not a scenario,
        even though it contains multiple statements.
      - Handoff behavior is a scenario candidate only when part of a larger intake, qualification, or specialized handling workflow.
      - Global rules like "if not in docs, escalate", "ask one clarifying question", "do not answer account-specific
        questions", or "tell the user support will review" belong in Guardrails or Response Guidelines, not Scenario Candidates.
      - Broad buckets like "account-specific issue escalation", "unknown question escalation", "contact support",
        "fallback to human", or "documentation unavailable" are not scenario candidates.
      - If a scenario candidate requires tools, reference the available tool explicitly inside the scenario instruction
        using markdown tool links such as [Handoff to Human](tool://handoff).
      - Use only tool IDs listed in available_agent_tools. If a needed tool is unavailable or the workflow depends on
        unavailable runtime data such as FAQ relevance scores or business-hours status, place it in Needs Review instead.
      - Only factual or product-specific knowledge should become FAQs/Documents candidates.
      - Generic capability statements such as "answer product questions", "help with billing",
        "troubleshoot common issues", or "direct to documentation" are not FAQ/document candidates.
        Put them in Business/Product Context or Response Guidelines when useful.
      - Product facts, pricing, policies, setup steps, troubleshooting facts, support hours, emergency contacts,
        and operational details should become FAQs/Documents candidates, not trusted approved knowledge.
      - If unsure, place content in Needs Review with a reason.
      - Use "high", "medium", or "low" confidence values only.
      - Return data that matches the provided schema.

    PROMPT
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
