require 'rails_helper'

RSpec.describe Captain::Llm::EmbeddingService do
  let(:service) { described_class.new }
  let(:client) { instance_double(OpenAI::Client) }
  let(:content) { 'Test content for embedding' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
  end

  describe '#get_embedding' do
    let(:embedding) { [0.1, 0.2, 0.3] }
    let(:openai_response) do
      {
        'data' => [
          {
            'embedding' => embedding
          }
        ]
      }
    end

    context 'when successful' do
      before do
        allow(client).to receive(:embeddings).and_return(openai_response)
      end

      it 'returns embedding array' do
        expect(service.get_embedding(content)).to eq(embedding)
      end

      it 'uses default model' do
        service.get_embedding(content)
        expect(client).to have_received(:embeddings).with(
          parameters: {
            model: described_class::DEFAULT_MODEL,
            input: content
          }
        )
      end

      it 'accepts custom model' do
        custom_model = 'text-embedding-ada-002'
        service.get_embedding(content, model: custom_model)
        expect(client).to have_received(:embeddings).with(
          parameters: {
            model: custom_model,
            input: content
          }
        )
      end
    end

    context 'when API call fails' do
      before do
        allow(client).to receive(:embeddings).and_raise(StandardError.new('API Error'))
      end

      it 'raises EmbeddingsError with message' do
        expect { service.get_embedding(content) }.to raise_error(
          Captain::Llm::EmbeddingService::EmbeddingsError,
          'Failed to create an embedding: API Error'
        )
      end
    end
  end
end
