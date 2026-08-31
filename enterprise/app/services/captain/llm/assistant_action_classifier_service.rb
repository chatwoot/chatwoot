class Captain::Llm::AssistantActionClassifierService < Llm::BaseAiService
  include Integrations::LlmInstrumentation
  include Captain::Llm::AssistantResponseInspectionHelpers

  def initialize(assistant:, conversation:)
    super(feature: 'assistant', account: conversation.account)
    @assistant = assistant
    @conversation = conversation
    @temperature = 0.0
  end

  def classify(message_history:, assistant_response:)
    user_prompt = assistant_response_inspection_prompt(
      message_history: message_history,
      assistant_response: assistant_response,
      response_tag: 'assistant_response_to_classify'
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
      has_custom_instructions: @assistant.config['instructions'].present?
    )
  end
end
