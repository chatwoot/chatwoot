require 'rails_helper'

RSpec.describe Captain::Llm::EmbeddingService do
  let(:context) { instance_double(RubyLLM::Context) }
  let(:embedding_response) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Llm::Config).to receive(:initialize!)
    allow(Llm::Config).to receive(:embedding_api_base)
    allow(Llm::Config).to receive(:default_provider).and_return(Llm::Config::DEFAULT_PROVIDER)
    allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(true)
    allow(Llm::Config).to receive(:with_api_key).and_yield(context)
    allow(context).to receive(:embed).and_return(embedding_response)
  end

  describe '#get_embedding' do
    it 'requests default embedding dimensions' do
      described_class.new.get_embedding('refund policy')

      expect(Llm::Config).to have_received(:with_api_key)
        .with('test-key', provider: Llm::Config::DEFAULT_PROVIDER, api_base: nil)
      expect(context).to have_received(:embed).with(
        'refund policy',
        model: LlmConstants::DEFAULT_EMBEDDING_MODEL,
        provider: Llm::Config::DEFAULT_PROVIDER,
        assume_model_exists: true,
        dimensions: LlmConstants::DEFAULT_EMBEDDING_DIMENSIONS
      )
    end

    it 'uses the embedding API key when Captain LLM uses another provider' do
      create(:installation_config, name: 'CAPTAIN_EMBEDDING_API_KEY', value: 'embedding-key')
      allow(Llm::Config).to receive(:default_provider).and_return('anthropic')
      allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(false)

      described_class.new.get_embedding('refund policy')

      expect(Llm::Config).to have_received(:with_api_key)
        .with('embedding-key', provider: Llm::Config::DEFAULT_PROVIDER, api_base: nil)
    end

    it 'fails clearly when Captain LLM uses another provider without an embedding API key' do
      allow(Llm::Config).to receive(:default_provider).and_return('openrouter')
      allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(false)

      expect { described_class.new.get_embedding('refund policy') }
        .to raise_error(
          Captain::Llm::EmbeddingService::EmbeddingsError,
          'CAPTAIN_EMBEDDING_API_KEY is required when Captain LLM uses a non-OpenAI provider or a custom API base.'
        )
      expect(Llm::Config).not_to have_received(:with_api_key)
    end

    it 'fails clearly when OpenAI provider uses a custom API base without an embedding API key' do
      allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(false)

      expect { described_class.new.get_embedding('refund policy') }
        .to raise_error(
          Captain::Llm::EmbeddingService::EmbeddingsError,
          'CAPTAIN_EMBEDDING_API_KEY is required when Captain LLM uses a non-OpenAI provider or a custom API base.'
        )
      expect(Llm::Config).not_to have_received(:with_api_key)
    end
  end
end
