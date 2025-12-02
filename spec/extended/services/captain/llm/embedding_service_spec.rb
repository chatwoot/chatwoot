require 'rails_helper'

RSpec.describe Captain::Llm::EmbeddingService do
  let(:api_key) { 'test_key' }
  let(:service) { described_class.new(api_key: api_key) }
  let(:client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).with(access_token: api_key, log_errors: anything).and_return(client)
  end

  describe '#generate' do
    it 'returns the embedding array' do
      expected_embedding = [0.1, 0.2, 0.3]
      allow(client).to receive(:embeddings).and_return({
                                                         'data' => [{ 'embedding' => expected_embedding }]
                                                       })

      result = service.generate('test text')
      expect(result).to eq(expected_embedding)
    end

    it 'raises an error on failure' do
      allow(client).to receive(:embeddings).and_raise(StandardError.new('API Error'))

      expect do
        service.generate('test text')
      end.to raise_error(StandardError, 'API Error')
    end
  end
end
