class Captain::Llm::AutoCategorizationService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(conversation)
    super()
    @conversation = conversation
    @account = conversation.account
    @content = conversation.to_llm_text
    @available_labels = @account.labels.pluck(:title)
  end

  def perform
    return if @content.blank?

    categorize_conversation
  end

  private

  def categorize_conversation
    result = generate_categorization
    return if result.blank?

    update_conversation(result)
  end

  def update_conversation(result)
    priority = result['priority']
    labels   = result['labels'] || []

    attrs = {}

    # Only set priority if it's a valid value
    attrs[:priority] = priority if Conversation.priorities.keys.include?(priority)

    @conversation.update!(attrs) if attrs.any?

    # Update labels separately (uses taggable gem method, not a plain column)
    valid_labels = labels.select { |l| @available_labels.include?(l) }
    @conversation.update_labels(valid_labels) if valid_labels.any?
  end

  def generate_categorization
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
      span_name: 'llm.captain.auto_categorization',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      feature_name: 'auto_categorization',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { conversation_id: @conversation.id }
    }
  end

  def system_prompt
    <<~PROMPT
      You are an expert customer support routing assistant.
      Analyze the provided conversation and categorize it.

      Available Labels for categorization:
      [#{@available_labels.join(', ')}]

      Respond strictly in JSON format with the following keys:
      - 'priority': One of 'low', 'medium', 'high', 'urgent'. Evaluate based on urgency, frustration, or critical issues.
      - 'labels': An array of strings selecting the most relevant labels from the available list above. You can return an empty array if none fit. Only use labels EXACTLY as they appear in the available list.
    PROMPT
  end

  def parse_response(content)
    return nil if content.nil?

    JSON.parse(sanitize_json_response(content))
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    nil
  end
end
