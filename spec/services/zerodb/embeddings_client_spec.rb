require 'rails_helper'

RSpec.describe Zerodb::EmbeddingsClient, type: :service do
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }
  let(:client) { described_class.new }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#generate_embedding' do
    let(:text) { 'This is a test message for embedding' }
    let(:endpoint) { "/#{project_id}/embeddings/generate" }
    let(:embedding_vector) { Array.new(1536) { rand } }

    context 'when request is successful' do
      let(:response_body) do
        {
          'embedding' => embedding_vector,
          'model' => 'text-embedding-3-small',
          'dimension' => 1536,
          'usage' => { 'tokens' => 10 }
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            body: {
              text: text,
              model: 'text-embedding-3-small'
            }.to_json,
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'returns embedding vector' do
        result = client.generate_embedding(text)
        expect(result['embedding']).to eq(embedding_vector)
        expect(result['dimension']).to eq(1536)
      end

      it 'uses default model when not specified' do
        client.generate_embedding(text)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('model' => 'text-embedding-3-small'))
      end
    end

    context 'when custom model is specified' do
      let(:custom_model) { 'text-embedding-3-large' }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('model' => custom_model))
          .to_return(status: 200, body: { embedding: embedding_vector }.to_json)
      end

      it 'uses the specified model' do
        client.generate_embedding(text, model: custom_model)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('model' => custom_model))
      end
    end

    context 'when text is blank' do
      it 'raises ValidationError for empty string' do
        expect { client.generate_embedding('') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Text cannot be blank'
        )
      end

      it 'raises ValidationError for nil' do
        expect { client.generate_embedding(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Text cannot be blank'
        )
      end

      it 'raises ValidationError for whitespace only' do
        expect { client.generate_embedding('   ') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Text cannot be blank'
        )
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(
            status: 500,
            body: { error: 'Embedding service unavailable' }.to_json
          )
      end

      it 'raises ZeroDBError' do
        expect { client.generate_embedding(text) }.to raise_error(
          Zerodb::BaseService::ZeroDBError
        )
      end
    end

    context 'when rate limit is exceeded' do
      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(
            status: 429,
            body: { error: 'Rate limit exceeded' }.to_json
          )
      end

      it 'raises RateLimitError' do
        expect { client.generate_embedding(text) }.to raise_error(
          Zerodb::BaseService::RateLimitError
        )
      end
    end
  end

  describe '#embed_and_store' do
    let(:endpoint) { "/#{project_id}/embeddings/embed-and-store" }
    let(:documents) do
      [
        { text: 'First document', metadata: { type: 'message', id: 1 } },
        { text: 'Second document', metadata: { type: 'note', id: 2 } }
      ]
    end

    context 'when request is successful' do
      let(:response_body) do
        {
          'stored' => 2,
          'vectors' => [
            { 'id' => 'vec_1', 'dimension' => 1536 },
            { 'id' => 'vec_2', 'dimension' => 1536 }
          ]
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            body: {
              documents: documents,
              namespace: 'default',
              model: 'text-embedding-3-small'
            }.to_json
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'stores documents and returns response' do
        result = client.embed_and_store(documents)
        expect(result['stored']).to eq(2)
        expect(result['vectors'].length).to eq(2)
      end

      it 'uses default namespace when not specified' do
        client.embed_and_store(documents)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => 'default'))
      end
    end

    context 'when custom namespace is specified' do
      let(:custom_namespace) { 'conversations' }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => custom_namespace))
          .to_return(status: 200, body: { stored: 2 }.to_json)
      end

      it 'uses the specified namespace' do
        client.embed_and_store(documents, namespace: custom_namespace)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => custom_namespace))
      end
    end

    context 'when documents array is empty' do
      it 'raises ValidationError' do
        expect { client.embed_and_store([]) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Documents array cannot be empty'
        )
      end
    end

    context 'when documents is nil' do
      it 'raises ValidationError' do
        expect { client.embed_and_store(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Documents array cannot be empty'
        )
      end
    end

    context 'when documents is not an array' do
      it 'raises ValidationError' do
        expect { client.embed_and_store('not an array') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Documents must be an array'
        )
      end
    end

    context 'when document is not a hash' do
      let(:invalid_docs) { ['string document', { text: 'valid' }] }

      it 'raises ValidationError with index' do
        expect { client.embed_and_store(invalid_docs) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Document at index 0 must be a hash/
        )
      end
    end

    context 'when document is missing text field' do
      let(:invalid_docs) { [{ metadata: { id: 1 } }] }

      it 'raises ValidationError' do
        expect { client.embed_and_store(invalid_docs) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Document at index 0 must have 'text' field/
        )
      end
    end

    context 'when document text is blank' do
      let(:invalid_docs) { [{ text: '   ', metadata: {} }] }

      it 'raises ValidationError' do
        expect { client.embed_and_store(invalid_docs) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Text in document at index 0 cannot be blank/
        )
      end
    end

    context 'when using string keys instead of symbols' do
      let(:string_key_docs) do
        [
          { 'text' => 'Document with string keys', 'metadata' => { 'id' => 1 } }
        ]
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: { stored: 1 }.to_json)
      end

      it 'accepts documents with string keys' do
        expect { client.embed_and_store(string_key_docs) }.not_to raise_error
      end
    end
  end

  describe '#batch_generate_embeddings' do
    let(:endpoint) { "/#{project_id}/embeddings/batch" }
    let(:texts) { ['First text', 'Second text', 'Third text'] }

    context 'when request is successful' do
      let(:embeddings) { Array.new(3) { Array.new(1536) { rand } } }
      let(:response_body) do
        {
          'embeddings' => embeddings,
          'model' => 'text-embedding-3-small',
          'count' => 3
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            body: {
              texts: texts,
              model: 'text-embedding-3-small'
            }.to_json
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'returns array of embeddings' do
        result = client.batch_generate_embeddings(texts)
        expect(result['embeddings'].length).to eq(3)
        expect(result['count']).to eq(3)
      end
    end

    context 'when texts array is empty' do
      it 'raises ValidationError' do
        expect { client.batch_generate_embeddings([]) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Texts array cannot be empty'
        )
      end
    end

    context 'when texts is not an array' do
      it 'raises ValidationError' do
        expect { client.batch_generate_embeddings('not an array') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Texts must be an array'
        )
      end
    end

    context 'when one text is blank' do
      let(:invalid_texts) { ['Valid text', '', 'Another valid text'] }

      it 'raises ValidationError with index' do
        expect { client.batch_generate_embeddings(invalid_texts) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Text at index 1 cannot be blank/
        )
      end
    end

    context 'when custom model is specified' do
      let(:custom_model) { 'text-embedding-3-large' }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('model' => custom_model))
          .to_return(status: 200, body: { embeddings: [] }.to_json)
      end

      it 'uses the specified model' do
        client.batch_generate_embeddings(texts, model: custom_model)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('model' => custom_model))
      end
    end
  end

  describe 'integration scenarios' do
    let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }
    let(:embed_store_endpoint) { "/#{project_id}/embeddings/embed-and-store" }

    context 'when generating and storing conversation messages' do
      let(:messages) do
        [
          { text: 'Hello, how can I help you?', metadata: { role: 'agent', conversation_id: 1 } },
          { text: 'I need help with my order', metadata: { role: 'customer', conversation_id: 1 } }
        ]
      end

      before do
        stub_request(:post, "#{api_url}#{embed_store_endpoint}")
          .to_return(
            status: 200,
            body: {
              stored: 2,
              vectors: [{ id: 'vec_1' }, { id: 'vec_2' }]
            }.to_json
          )
      end

      it 'successfully stores conversation messages' do
        result = client.embed_and_store(messages, namespace: 'conversations')
        expect(result['stored']).to eq(2)
      end
    end

    context 'when API is temporarily unavailable' do
      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_timeout.then
          .to_return(status: 200, body: { embedding: Array.new(1536, 0.1) }.to_json)
      end

      it 'retries and succeeds' do
        result = client.generate_embedding('Test message')
        expect(result).to have_key('embedding')
      end
    end

    context 'when authentication fails' do
      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_return(
            status: 401,
            body: { error: 'Invalid API key' }.to_json
          )
      end

      it 'raises AuthenticationError' do
        expect { client.generate_embedding('Test') }.to raise_error(
          Zerodb::BaseService::AuthenticationError
        )
      end
    end
  end
end
