class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_dimensions = LlmConstants::DEFAULT_EMBEDDING_DIMENSIONS
    @embedding_provider = Llm::Config.default_embedding_provider
    @api_key = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_API_KEY')&.value.presence ||
               system_openai_api_key
  end

  def get_embedding(content, model: LlmConstants::DEFAULT_EMBEDDING_MODEL)
    return [] if content.blank?

    instrument_embedding_call(instrumentation_params(content, model)) do
      validate_api_key!

      Llm::Config.with_api_key(@api_key, provider: @embedding_provider, api_base: Llm::Config.embedding_api_base) do |context|
        context.embed(
          content,
          model: model,
          provider: @embedding_provider,
          assume_model_exists: true,
          dimensions: @embedding_dimensions
        ).vectors
      end
    end
  rescue EmbeddingsError => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end

  private

  def system_openai_api_key
    return unless Llm::Config.default_openai_endpoint?

    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  def validate_api_key!
    return if @api_key.present?

    raise EmbeddingsError, 'CAPTAIN_EMBEDDING_API_KEY is required when Captain LLM uses a non-OpenAI provider or a custom API base.'
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      provider: @embedding_provider,
      dimensions: @embedding_dimensions,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
