require 'openai'

class Captain::Llm::Providers::OpenaiProvider < Captain::Llm::Providers::BaseProvider
  def initialize(api_key:, endpoint: nil, **_options)
    super
    @client = OpenAI::Client.new(
      access_token: api_key,
      uri_base: endpoint || 'https://api.openai.com/',
      log_errors: Rails.env.development?
    )
  end

  def chat(messages:, model:, functions: [], json_mode: true)
    params = {
      model: model,
      messages: messages
    }
    params[:response_format] = { type: 'json_object' } if json_mode
    params[:tools] = functions if functions.any?

    @client.chat(parameters: params)
  end

  def embedding(text:, model:)
    @client.embeddings(
      parameters: {
        model: model,
        input: text
      }
    )
  end
end
