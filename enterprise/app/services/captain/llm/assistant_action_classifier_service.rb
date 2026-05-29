class Captain::Llm::AssistantActionClassifierService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  MAX_CONTEXT_MESSAGES = 10

  def initialize(assistant:, conversation:)
    super()
    @assistant = assistant
    @conversation = conversation
    @temperature = 0.0
  end

  def classify(message_history:, assistant_response:)
    user_prompt = classification_user_prompt(
      message_history: message_history,
      assistant_response: assistant_response
    )

    response = instrument_llm_call(instrumentation_params(user_prompt)) do
      chat(model: @model, temperature: @temperature)
        .with_schema(Captain::AssistantActionSchema)
        .with_instructions(system_prompt)
        .ask(user_prompt)
    end

    parsed = parse_response(response.content)
    normalize_response(parsed, response.content)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    Rails.logger.warn(
      "[CAPTAIN][AssistantActionClassifier] Failed for conversation #{@conversation.display_id}: #{e.class.name}: #{e.message}"
    )
    { 'action' => nil, 'action_reason' => nil, 'error' => e.message, 'model' => @model }
  end

  private

  def classification_user_prompt(message_history:, assistant_response:)
    <<~PROMPT
      <account_custom_instructions>
      #{@assistant.config['instructions']}
      </account_custom_instructions>

      <conversation_context>
      #{format_conversation_context(message_history)}
      </conversation_context>

      <assistant_response_to_classify>
      #{assistant_response}
      </assistant_response_to_classify>
    PROMPT
  end

  def normalize_messages(message_history)
    message_history.filter_map do |message|
      role = message[:role] || message['role']
      next if role.blank?

      { role: role.to_s, content: normalize_content(message[:content] || message['content']) }
    end
  end

  def normalize_content(content)
    return content if content.is_a?(String)
    return content.filter_map { |part| part[:text] || part['text'] if text_part?(part) }.join("\n") if content.is_a?(Array)

    content.to_s
  end

  def text_part?(part)
    return false unless part.is_a?(Hash)

    (part[:type] || part['type']).to_s == 'text'
  end

  def format_conversation_context(messages)
    normalize_messages(messages).last(MAX_CONTEXT_MESSAGES).filter_map do |message|
      content = message[:content].to_s.strip
      next if content.blank?

      "#{role_label(message[:role])}: #{content}"
    end.join("\n")
  end

  def role_label(role)
    return 'User' if role == 'user'
    return 'Assistant' if role == 'assistant'

    role.to_s.titleize
  end

  def parse_response(content)
    return content if content.is_a?(Hash)

    JSON.parse(sanitize_json_response(content))
  rescue JSON::ParserError, TypeError
    {}
  end

  def normalize_response(parsed, raw_content)
    action = parsed['action'].to_s
    reason = parsed['action_reason'].to_s
    return invalid_response(raw_content) unless Captain::AssistantActionSchema::ACTIONS.include?(action)

    {
      'action' => action,
      'action_reason' => reason.presence,
      'raw_response' => raw_content,
      'model' => @model
    }
  end

  def invalid_response(raw_content)
    {
      'action' => nil,
      'action_reason' => nil,
      'raw_response' => raw_content,
      'error' => 'invalid_classifier_response',
      'model' => @model
    }
  end

  def instrumentation_params(user_prompt)
    {
      span_name: 'llm.captain.assistant_action_classifier',
      model: @model,
      temperature: @temperature,
      account_id: @conversation.account_id,
      conversation_id: @conversation.display_id,
      feature_name: 'assistant_action_classifier',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: user_prompt }
      ],
      metadata: {
        assistant_id: @assistant.id,
        channel_type: @conversation.inbox&.channel_type,
        source: 'v1_response_builder'
      }
    }
  end

  def system_prompt
    Captain::Llm::SystemPromptsService.assistant_action_classifier(
      has_custom_instructions: @assistant.config['instructions'].present?,
      with_resolution_markers: @assistant.conversation_context_with_resolution_markers?
    )
  end
end
