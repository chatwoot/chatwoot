require 'rails_helper'

RSpec.describe Captain::Llm::EmbeddingService do
  let(:context) { instance_double(RubyLLM::Context) }
  let(:embedding_response) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    create(:installation_config, name: 'CAPTAIN_EMBEDDING_API_KEY', value: 'embedding-key')
    allow(Llm::Config).to receive(:initialize!)
    allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(true)
    allow(Llm::Config).to receive(:with_api_key).and_yield(context)
    allow(context).to receive(:embed).and_return(embedding_response)
  end

  describe '#get_embedding' do
    it 'requests default embedding dimensions' do
      described_class.new.get_embedding('refund policy')

      expect(Llm::Config).to have_received(:with_api_key)
        .with('embedding-key', provider: Llm::Config::DEFAULT_PROVIDER, api_base: Llm::OpenAiConfig.api_v1_base)
      expect(context).to have_received(:embed).with(
        'refund policy',
        model: LlmConstants::DEFAULT_EMBEDDING_MODEL,
        provider: Llm::Config::DEFAULT_PROVIDER,
        assume_model_exists: true,
        dimensions: LlmConstants::DEFAULT_EMBEDDING_DIMENSIONS
      )
    end

    it 'uses the embedding API key when Captain LLM uses another provider' do
      allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(false)

      described_class.new.get_embedding('refund policy')

      expect(Llm::Config).to have_received(:with_api_key)
        .with('embedding-key', provider: Llm::Config::DEFAULT_PROVIDER, api_base: Llm::OpenAiConfig.api_v1_base)
    end

    it 'uses the configured embedding model' do
      create(:installation_config, name: 'CAPTAIN_EMBEDDING_MODEL', value: 'text-embedding-3-large')

      described_class.new.get_embedding('refund policy')

      expect(context).to have_received(:embed).with(
        'refund policy',
        model: 'text-embedding-3-large',
        provider: Llm::Config::DEFAULT_PROVIDER,
        assume_model_exists: true,
        dimensions: LlmConstants::DEFAULT_EMBEDDING_DIMENSIONS
      )
    end

    it 'fails clearly when Captain LLM uses another provider without an embedding API key' do
      InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_API_KEY')&.destroy
      allow(Llm::Config).to receive(:default_openai_endpoint?).and_return(false)

      expect { described_class.new.get_embedding('refund policy') }
        .to raise_error(
          Llm::ConfigurationError,
          'An OpenAI API key is required for embeddings and document search.'
        )
      expect(Llm::Config).not_to have_received(:with_api_key)
    end
  end
end
