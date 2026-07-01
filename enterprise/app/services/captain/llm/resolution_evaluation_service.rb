class Captain::Llm::ResolutionEvaluationService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(conversation)
    super()
    @conversation = conversation
    @account = conversation.account
    @content = conversation.to_llm_text
  end

  def perform
    return if @content.blank?
    
    # Check if AI was involved in this conversation
    # A simple heuristic: if a Captain Assistant bot is the assignee, or if there's any outgoing message by an agent_bot.
    bot_messages = @conversation.messages.outgoing.where(sender_type: 'AgentBot')
    return unless bot_messages.any? || @conversation.assignee_id.nil?

    evaluate_resolution
  end

  private

  def evaluate_resolution
    result = generate_evaluation
    return if result.blank?

    confidence = result['confidence'].to_f
    resolved_by_ai = result['resolved_by_ai'] == true

    @conversation.update!(
      resolved_by_ai: resolved_by_ai,
      ai_resolution_confidence: confidence,
      ai_resolved_at: Time.current
    )
  end

  def generate_evaluation
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end
    parse_response(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    nil
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.resolution_evaluation',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      feature_name: 'ai_resolution_tracking',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { conversation_id: @conversation.id }
    }
  end

  def system_prompt
    <<~PROMPT
      You are an expert customer support analyst.
      Analyze the provided conversation transcript, which has just been marked as resolved.
      
      Determine if the customer's issue was successfully resolved by the AI assistant without requiring human intervention.

      Respond strictly in JSON format with the following keys:
      - 'resolved_by_ai': (boolean) true if the AI provided the solution and the customer seems satisfied or didn't request a human agent, false if a human agent stepped in to resolve it.
      - 'confidence': (float 0.0 to 100.0) Your confidence level that the issue was actually solved by the AI.
    PROMPT
  end

  def parse_response(content)
    return nil if content.nil?

    JSON.parse(sanitize_json_response(content))
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response for resolution evaluation: #{e.message}"
    nil
  end
end
