# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Llm::EmbeddingService do
  let(:service) { described_class.new }
  let(:mock_provider) { instance_double(Captain::Providers::OpenaiProvider) }

  before do
    allow(Captain::Providers::Factory).to receive(:create).and_return(mock_provider)
  end

  describe '.embedding_model' do
    it 'returns the embedding model from Captain::Config' do
      allow(Captain::Config).to receive(:current_provider).and_return('openai')
      allow(Captain::Config).to receive(:config_for).with('openai').and_return({
                                                                                 embedding_model: 'text-embedding-3-small'
                                                                               })

      expect(described_class.embedding_model).to eq('text-embedding-3-small')
    end
  end

  describe '#get_embedding' do
    it 'calls provider embeddings and returns the embedding vector' do
      content = 'Test content for embedding'
      model = 'text-embedding-3-small'

      mock_response = {
        'data' => [
          {
            'embedding' => [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        ]
      }

      expect(mock_provider).to receive(:embeddings).with(
        parameters: {
          model: model,
          input: content
        }
      ).and_return(mock_response)

      result = service.get_embedding(content, model: model)
      expect(result).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
    end

    it 'raises EmbeddingsError on failure' do
      content = 'Test content'

      allow(mock_provider).to receive(:embeddings).and_raise(StandardError.new('API Error'))

      expect do
        service.get_embedding(content)
      end.to raise_error(Captain::Llm::EmbeddingService::EmbeddingsError, /Failed to create an embedding/)
    end
  end
end
