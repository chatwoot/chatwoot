class Captain::Llm::FaqGeneratorService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(document:)
    super()
    @document = document
    @content = document.content
    @language = document.account.locale_english_name
    @account_id = document.account_id
  end

  def generate
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end

    parse_response(response.content)
  rescue RubyLLM::Error => e
    Rails.logger.error "LLM API Error: #{e.message}"
    []
  end

  private

  attr_reader :content, :language

  def system_prompt
    Captain::Llm::SystemPromptsService.faq_generator(language)
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.faq_generator',
      model: @model,
      temperature: @temperature,
      feature_name: 'faq_generator',
      account_id: @account_id,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: document_metadata
    }
  end

  def document_metadata
    @document&.to_llm_metadata || {}
  end

  def parse_response(content)
    return [] if content.nil?

    JSON.parse(sanitize_json_response(content)).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
