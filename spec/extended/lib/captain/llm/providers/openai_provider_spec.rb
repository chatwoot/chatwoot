require 'rails_helper'

RSpec.describe Captain::Llm::Providers::OpenaiProvider do
  let(:api_key) { 'test_api_key' }
  let(:provider) { described_class.new(api_key: api_key) }
  let(:client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(client)
  end

  describe '#chat' do
    let(:messages) { [{ 'role' => 'user', 'content' => 'Hello' }] }
    let(:model) { 'gpt-4o' }
    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => 'Hello there'
            }
          }
        ]
      }
    end

    it 'calls OpenAI API with correct parameters' do
      expect(client).to receive(:chat).with(
        parameters: {
          model: model,
          messages: messages,
          response_format: { type: 'json_object' }
        }
      ).and_return(openai_response)

      response = provider.chat(messages: messages, model: model)

      expect(response).to eq(openai_response)
    end
  end

  describe '#embedding' do
    let(:text) { 'test text' }
    let(:model) { 'text-embedding-3-small' }
    let(:embedding_response) do
      {
        'data' => [
          { 'embedding' => [0.1, 0.2, 0.3] }
        ]
      }
    end

    it 'calls OpenAI embedding API' do
      expect(client).to receive(:embeddings).with(
        parameters: {
          model: model,
          input: text
        }
      ).and_return(embedding_response)

      response = provider.embedding(text: text, model: model)

      expect(response).to eq(embedding_response)
    end
  end
end
