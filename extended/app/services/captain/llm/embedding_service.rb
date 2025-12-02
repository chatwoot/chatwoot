require 'openai'

require_relative '../../../../lib/captain/llm/providers/openai_provider'
require_relative '../../../../lib/captain/llm/providers/gemini_provider'

class Captain::Llm::EmbeddingService
  def initialize(api_key: nil, provider: nil)
    @provider = provider || ENV['CAPTAIN_LLM_PROVIDER'] || 'openai'
    @api_key = api_key || default_api_key
    @client = create_client
  end

  def generate(text, model: default_model)
    response = @client.embedding(text: text, model: model)
    extract_embedding(response)
  rescue StandardError => e
    Rails.logger.error("EmbeddingService Error: #{e.message}")
    raise e
  end

  # Alias for backward compatibility with existing code
  alias get_embedding generate

  private

  def default_api_key
    case @provider
    when 'gemini'
      ENV.fetch('GEMINI_API_KEY', nil)
    else
      ENV.fetch('OPENAI_API_KEY', nil)
    end
  end

  def default_model
    case @provider
    when 'gemini'
      'text-embedding-004'
    else
      'text-embedding-3-small'
    end
  end

  def create_client
    case @provider
    when 'gemini'
      Captain::Llm::Providers::GeminiProvider.new(api_key: @api_key)
    else
      Captain::Llm::Providers::OpenaiProvider.new(api_key: @api_key)
    end
  end

  def extract_embedding(response)
    response.dig('data', 0, 'embedding') || []
  end
end
