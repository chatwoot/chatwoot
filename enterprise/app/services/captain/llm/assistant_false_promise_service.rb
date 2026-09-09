class Captain::Llm::AssistantFalsePromiseService < Llm::BaseAiService
  DETECTOR_MODEL = 'gpt-5.2'.freeze

  include Integrations::LlmInstrumentation
  include Captain::Llm::AssistantResponseInspectionHelpers

  def initialize(assistant:, conversation:)
    super()
    @assistant = assistant
    @conversation = conversation
    @temperature = 0.0
  end

  def detect(message_history:, assistant_response:)
    user_prompt = assistant_response_inspection_prompt(
      message_history: message_history,
      assistant_response: assistant_response,
      response_tag: 'assistant_response_to_check'
    )

    response = instrument_llm_call(instrumentation_params(user_prompt)) do
      chat(model: @model, temperature: @temperature)
        .with_schema(Captain::AssistantFalsePromiseSchema)
        .with_instructions(system_prompt)
        .ask(user_prompt)
    end

    parsed = parse_response(response.content)
    normalize_response(parsed, response.content)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    Rails.logger.warn(
      "[CAPTAIN][AssistantFalsePromise] Failed for conversation #{@conversation.display_id}: #{e.class.name}: #{e.message}"
    )
    { 'decision' => nil, 'reason' => nil, 'error' => e.message, 'model' => @model }
  end

  private

  def setup_model
    @model = DETECTOR_MODEL
  end

  def normalize_response(parsed, raw_content)
    decision = parsed['decision'].to_s
    reason = parsed['reason'].to_s
    return invalid_response(raw_content) unless Captain::AssistantFalsePromiseSchema::DECISIONS.include?(decision)

    {
      'decision' => decision,
      'reason' => reason.presence,
      'raw_response' => raw_content,
      'model' => @model
    }
  end

  def invalid_response(raw_content)
    {
      'decision' => nil,
      'reason' => nil,
      'raw_response' => raw_content,
      'error' => 'invalid_false_promise_response',
      'model' => @model
    }
  end

  def instrumentation_params(user_prompt)
    {
      span_name: 'llm.captain.assistant_false_promise_detector',
      model: @model,
      temperature: @temperature,
      account_id: @conversation.account_id,
      conversation_id: @conversation.display_id,
      feature_name: 'assistant_false_promise_detector',
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
    Captain::Llm::SystemPromptsService.assistant_false_promise_detector
  end
end
