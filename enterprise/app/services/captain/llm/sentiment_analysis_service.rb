class Captain::Llm::SentimentAnalysisService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(message)
    super()
    @message = message
    @content = message.content
  end

  def perform
    return if @content.blank?

    generate_and_update_sentiment
  end

  private

  def generate_and_update_sentiment
    sentiment_data = generate_sentiment
    return if sentiment_data.blank?

    @message.update!(sentiment: sentiment_data)
  end

  def generate_sentiment
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end
    parse_response(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @message.account).capture_exception
    nil
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.sentiment_analysis',
      model: @model,
      temperature: @temperature,
      account_id: @message.account_id,
      feature_name: 'sentiment_analysis',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { message_id: @message.id }
    }
  end

  def system_prompt
    <<~PROMPT
      You are an expert customer service sentiment analyzer.
      Analyze the sentiment of the following customer message.
      Respond strictly in JSON format with the following keys:
      - 'label': One of 'positive', 'neutral', 'negative', 'angry'
      - 'score': A float between -1.0 (most negative) and 1.0 (most positive)
      - 'aspects': An array of strings identifying what the customer is talking about (e.g., ['pricing', 'support', 'onboarding']). If none, return empty array.
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
