class Captain::Llm::AutoQaService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(conversation)
    super()
    @conversation = conversation
    @account = conversation.account
    @content = conversation.to_llm_text
  end

  def perform
    return if @content.blank?
    # Ensure it's handled by human, or at least has agent responses
    agent_messages = @conversation.messages.outgoing.where.not(sender_type: 'AgentBot')
    return unless agent_messages.any?

    evaluate_qa
  end

  private

  def evaluate_qa
    result = generate_qa_evaluation
    return if result.blank?

    score = result['score'].to_f
    feedback = result['feedback']

    @conversation.update!(
      auto_qa_score: score,
      auto_qa_feedback: feedback
    )
  end

  def generate_qa_evaluation
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
      span_name: 'llm.captain.auto_qa',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      feature_name: 'auto_qa',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { conversation_id: @conversation.id }
    }
  end

  def system_prompt
    <<~PROMPT
      You are an expert Quality Assurance reviewer for customer support conversations.
      Analyze the provided transcript of a conversation handled by a human agent.

      Evaluate the agent's performance based on:
      1. Politeness and empathy.
      2. Clarity of communication.
      3. Problem resolution and correctness of information.
      4. Professionalism.

      Respond strictly in JSON format with the following keys:
      - 'score': A float between 0.0 and 100.0 representing the overall quality score.
      - 'feedback': A short paragraph containing constructive feedback for the human agent, detailing what went well and what could be improved.
    PROMPT
  end

  def parse_response(content)
    return nil if content.nil?

    JSON.parse(sanitize_json_response(content))
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response for Auto QA: #{e.message}"
    nil
  end
end
