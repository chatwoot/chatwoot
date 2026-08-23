class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_model = self.class.embedding_model
  end

  def self.embedding_model
    Llm::Config.embedding_model
  end

  def get_embedding(content, model: @embedding_model)
    return [] if content.blank?

    instrument_embedding_call(instrumentation_params(content, model)) do
      RubyLLM.embed(
        content,
        model: model,
        provider: embedding_provider(model),
        assume_model_exists: true
      ).vectors
    end
  rescue RubyLLM::Error => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end

  private

  # The embedding model may be a custom model id (e.g. an OpenRouter model with a
  # `provider/name:free` format) that RubyLLM has no registry entry for. Declaring
  # the provider explicitly and assuming the model exists lets us use any model the
  # configured endpoint supports instead of failing on unknown model ids.
  def embedding_provider(model)
    Llm::Config.provider_for(model) || provider_from_endpoint || :openai
  end

  def provider_from_endpoint
    endpoint = Llm::Config.openai_endpoint
    return :openrouter if endpoint&.include?('openrouter.ai')

    nil
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
