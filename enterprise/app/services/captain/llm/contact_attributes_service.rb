class Captain::Llm::ContactAttributesService < Llm::BaseAiService
  include Integrations::LlmInstrumentation
  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @content = "#Contact\n\n#{@contact.to_llm_text} \n\n#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def generate_and_update_attributes
    generate_attributes
    # to implement the update attributes
  end

  private

  attr_reader :content

  def generate_attributes
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

  def instrumentation_params
    {
      span_name: 'llm.captain.contact_attributes',
      account_id: hook.account_id,
      conversation_id: conversation&.display_id,
      feature_name: 'contact_attributes',
      model: @model,
      temperature: @temperature,
      messages: [
        {
          role: 'system',
          content: system_prompt
        },
        {
          role: 'user',
          content: @content
        }
      ]
    }
  end

  def system_prompt
    Captain::Llm::SystemPromptsService.attributes_generator
  end

  def parse_response(content)
    return [] if content.nil?

    JSON.parse(content.strip).fetch('attributes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
