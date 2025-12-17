require 'rails_helper'

RSpec.describe Zerodb::VectorClient, type: :service do
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }
  let(:client) { described_class.new }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#upsert_vector' do
    let(:vector_id) { 'vec_test_123' }
    let(:vector) { Array.new(1536) { rand } }
    let(:metadata) { { type: 'message', conversation_id: 1, text: 'Hello world' } }
    let(:endpoint) { "/#{project_id}/vectors/upsert" }

    context 'when request is successful' do
      let(:response_body) do
        {
          'id' => vector_id,
          'status' => 'created',
          'dimension' => 1536
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            body: {
              id: vector_id,
              vector: vector,
              metadata: metadata,
              namespace: 'default'
            }.to_json,
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'upserts vector successfully' do
        result = client.upsert_vector(vector_id, vector, metadata)
        expect(result['id']).to eq(vector_id)
        expect(result['status']).to eq('created')
      end

      it 'uses default namespace when not specified' do
        client.upsert_vector(vector_id, vector, metadata)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => 'default'))
      end
    end

    context 'when custom namespace is specified' do
      let(:custom_namespace) { 'conversations' }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => custom_namespace))
          .to_return(status: 200, body: { id: vector_id }.to_json)
      end

      it 'uses the specified namespace' do
        client.upsert_vector(vector_id, vector, metadata, namespace: custom_namespace)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => custom_namespace))
      end
    end

    context 'when vector_id is blank' do
      it 'raises ValidationError' do
        expect { client.upsert_vector('', vector, metadata) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector ID cannot be blank'
        )
      end
    end

    context 'when vector is nil' do
      it 'raises ValidationError' do
        expect { client.upsert_vector(vector_id, nil, metadata) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector cannot be nil'
        )
      end
    end

    context 'when vector is not an array' do
      it 'raises ValidationError' do
        expect { client.upsert_vector(vector_id, 'not an array', metadata) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector must be an array'
        )
      end
    end

    context 'when vector is empty' do
      it 'raises ValidationError' do
        expect { client.upsert_vector(vector_id, [], metadata) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector cannot be empty'
        )
      end
    end

    context 'when vector dimension is unsupported' do
      let(:invalid_vector) { Array.new(512) { rand } }

      it 'raises ValidationError with dimension details' do
        expect { client.upsert_vector(vector_id, invalid_vector, metadata) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Vector dimension 512 is not supported/
        )
      end
    end

    context 'when using supported dimensions' do
      [384, 768, 1024, 1536].each do |dimension|
        it "accepts #{dimension}-dimensional vectors" do
          vector = Array.new(dimension) { rand }
          stub_request(:post, "#{api_url}#{endpoint}")
            .to_return(status: 200, body: { id: vector_id }.to_json)

          expect { client.upsert_vector(vector_id, vector, metadata) }.not_to raise_error
        end
      end
    end

    context 'when metadata is nil' do
      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('metadata' => {}))
          .to_return(status: 200, body: { id: vector_id }.to_json)
      end

      it 'uses empty hash for metadata' do
        client.upsert_vector(vector_id, vector, nil)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including('metadata' => {}))
      end
    end
  end

  describe '#batch_upsert_vectors' do
    let(:endpoint) { "/#{project_id}/vectors/batch-upsert" }
    let(:vectors) do
      [
        {
          id: 'vec_1',
          vector: Array.new(1536) { rand },
          metadata: { type: 'message', index: 1 }
        },
        {
          id: 'vec_2',
          vector: Array.new(1536) { rand },
          metadata: { type: 'message', index: 2 }
        }
      ]
    end

    context 'when request is successful' do
      let(:response_body) do
        {
          'inserted' => 2,
          'ids' => ['vec_1', 'vec_2']
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'batch upserts vectors successfully' do
        result = client.batch_upsert_vectors(vectors)
        expect(result['inserted']).to eq(2)
        expect(result['ids']).to eq(['vec_1', 'vec_2'])
      end
    end

    context 'when vectors array is empty' do
      it 'raises ValidationError' do
        expect { client.batch_upsert_vectors([]) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vectors array cannot be empty'
        )
      end
    end

    context 'when vectors is not an array' do
      it 'raises ValidationError' do
        expect { client.batch_upsert_vectors('not an array') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vectors must be an array'
        )
      end
    end

    context 'when vector object is not a hash' do
      let(:invalid_vectors) { ['string', { id: 'vec_1', vector: [] }] }

      it 'raises ValidationError with index' do
        expect { client.batch_upsert_vectors(invalid_vectors) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Vector at index 0 must be a hash/
        )
      end
    end

    context 'when vector object is missing id field' do
      let(:invalid_vectors) { [{ vector: Array.new(1536) { rand } }] }

      it 'raises ValidationError' do
        expect { client.batch_upsert_vectors(invalid_vectors) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Vector at index 0 must have 'id' field/
        )
      end
    end

    context 'when vector object is missing vector field' do
      let(:invalid_vectors) { [{ id: 'vec_1' }] }

      it 'raises ValidationError' do
        expect { client.batch_upsert_vectors(invalid_vectors) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Vector at index 0 must have 'vector' field/
        )
      end
    end
  end

  describe '#search_vectors' do
    let(:query_vector) { Array.new(1536) { rand } }
    let(:limit) { 10 }
    let(:endpoint) { "/#{project_id}/vectors/search" }

    context 'when search is successful' do
      let(:response_body) do
        {
          'results' => [
            { 'id' => 'vec_1', 'score' => 0.95, 'metadata' => { 'text' => 'Similar text 1' } },
            { 'id' => 'vec_2', 'score' => 0.87, 'metadata' => { 'text' => 'Similar text 2' } }
          ],
          'count' => 2
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            body: {
              query_vector: query_vector,
              limit: limit,
              namespace: 'default',
              threshold: 0.7,
              include_metadata: true,
              include_vectors: false
            }.to_json
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'returns search results with scores' do
        result = client.search_vectors(query_vector, limit)
        expect(result['results'].length).to eq(2)
        expect(result['results'][0]['score']).to eq(0.95)
      end

      it 'uses default parameters when not specified' do
        client.search_vectors(query_vector, limit)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including(
                  'namespace' => 'default',
                  'threshold' => 0.7,
                  'include_metadata' => true,
                  'include_vectors' => false
                ))
      end
    end

    context 'when custom parameters are specified' do
      let(:filters) { { type: 'message', conversation_id: 1 } }
      let(:custom_options) do
        {
          namespace: 'conversations',
          threshold: 0.85,
          include_metadata: false,
          include_vectors: true,
          filters: filters
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: { results: [] }.to_json)
      end

      it 'uses custom parameters' do
        client.search_vectors(query_vector, limit, custom_options)
        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with(body: hash_including(
                  'namespace' => 'conversations',
                  'threshold' => 0.85,
                  'include_metadata' => false,
                  'include_vectors' => true,
                  'filters' => filters
                ))
      end
    end

    context 'when query_vector is nil' do
      it 'raises ValidationError' do
        expect { client.search_vectors(nil, limit) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Query vector cannot be nil'
        )
      end
    end

    context 'when query_vector is not an array' do
      it 'raises ValidationError' do
        expect { client.search_vectors('not an array', limit) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Query vector must be an array'
        )
      end
    end

    context 'when query_vector is empty' do
      it 'raises ValidationError' do
        expect { client.search_vectors([], limit) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Query vector cannot be empty'
        )
      end
    end

    context 'when limit is not positive' do
      it 'raises ValidationError for zero' do
        expect { client.search_vectors(query_vector, 0) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Limit must be a positive integer'
        )
      end

      it 'raises ValidationError for negative' do
        expect { client.search_vectors(query_vector, -5) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Limit must be a positive integer'
        )
      end
    end

    context 'when limit exceeds maximum' do
      it 'raises ValidationError' do
        expect { client.search_vectors(query_vector, 1001) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Limit cannot exceed 1000'
        )
      end
    end
  end

  describe '#delete_vector' do
    let(:vector_id) { 'vec_to_delete' }
    let(:endpoint) { "/#{project_id}/vectors/delete" }

    context 'when deletion is successful' do
      let(:response_body) { { 'deleted' => true, 'id' => vector_id } }

      before do
        stub_request(:delete, "#{api_url}#{endpoint}")
          .with(
            body: {
              id: vector_id,
              namespace: 'default'
            }.to_json
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'deletes vector successfully' do
        result = client.delete_vector(vector_id)
        expect(result['deleted']).to be true
        expect(result['id']).to eq(vector_id)
      end
    end

    context 'when vector_id is blank' do
      it 'raises ValidationError' do
        expect { client.delete_vector('') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector ID cannot be blank'
        )
      end
    end

    context 'when custom namespace is specified' do
      before do
        stub_request(:delete, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => 'custom'))
          .to_return(status: 200, body: { deleted: true }.to_json)
      end

      it 'uses the specified namespace' do
        client.delete_vector(vector_id, namespace: 'custom')
        expect(WebMock).to have_requested(:delete, "#{api_url}#{endpoint}")
          .with(body: hash_including('namespace' => 'custom'))
      end
    end
  end

  describe '#get_vector' do
    let(:vector_id) { 'vec_get_test' }
    let(:endpoint) { "/#{project_id}/vectors/#{vector_id}" }

    context 'when vector exists' do
      let(:vector_data) { Array.new(1536) { rand } }
      let(:response_body) do
        {
          'id' => vector_id,
          'vector' => vector_data,
          'metadata' => { 'text' => 'Test message' },
          'dimension' => 1536
        }
      end

      before do
        stub_request(:get, "#{api_url}#{endpoint}")
          .with(
            query: {
              namespace: 'default',
              include_vector: true
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'retrieves vector data' do
        result = client.get_vector(vector_id)
        expect(result['id']).to eq(vector_id)
        expect(result['vector']).to eq(vector_data)
        expect(result['metadata']).to have_key('text')
      end
    end

    context 'when vector_id is blank' do
      it 'raises ValidationError' do
        expect { client.get_vector('') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Vector ID cannot be blank'
        )
      end
    end

    context 'when vector does not exist' do
      before do
        stub_request(:get, "#{api_url}#{endpoint}")
          .to_return(
            status: 404,
            body: { error: 'Vector not found' }.to_json
          )
      end

      it 'raises ZeroDBError' do
        expect { client.get_vector(vector_id) }.to raise_error(
          Zerodb::BaseService::ZeroDBError,
          /Resource not found/
        )
      end
    end
  end

  describe '#list_vectors' do
    let(:endpoint) { "/#{project_id}/vectors" }

    context 'when listing is successful' do
      let(:response_body) do
        {
          'vectors' => [
            { 'id' => 'vec_1', 'metadata' => { 'type' => 'message' } },
            { 'id' => 'vec_2', 'metadata' => { 'type' => 'note' } }
          ],
          'total' => 150,
          'offset' => 0,
          'limit' => 100
        }
      end

      before do
        stub_request(:get, "#{api_url}#{endpoint}")
          .with(
            query: {
              namespace: 'default',
              limit: 100,
              offset: 0
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'returns paginated vector list' do
        result = client.list_vectors
        expect(result['vectors'].length).to eq(2)
        expect(result['total']).to eq(150)
      end
    end

    context 'when custom pagination is specified' do
      before do
        stub_request(:get, "#{api_url}#{endpoint}")
          .with(query: hash_including('limit' => 50, 'offset' => 100))
          .to_return(status: 200, body: { vectors: [] }.to_json)
      end

      it 'uses custom pagination parameters' do
        client.list_vectors(limit: 50, offset: 100)
        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint}")
          .with(query: hash_including('limit' => 50, 'offset' => 100))
      end
    end

    context 'when filters are specified' do
      let(:filters) { { type: 'message', active: true } }

      before do
        stub_request(:get, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: { vectors: [] }.to_json)
      end

      it 'includes filters in query' do
        client.list_vectors(filters: filters)
        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint}")
          .with(query: hash_including('filters' => filters.to_json))
      end
    end
  end

  describe 'integration scenarios' do
    let(:vector) { Array.new(1536) { rand } }

    context 'when upserting and searching vectors' do
      before do
        stub_request(:post, %r{/vectors/upsert})
          .to_return(status: 200, body: { id: 'vec_1', status: 'created' }.to_json)

        stub_request(:post, %r{/vectors/search})
          .to_return(
            status: 200,
            body: {
              results: [{ id: 'vec_1', score: 0.99 }]
            }.to_json
          )
      end

      it 'successfully stores and retrieves vectors' do
        upsert_result = client.upsert_vector('vec_1', vector, { text: 'Test' })
        expect(upsert_result['status']).to eq('created')

        search_result = client.search_vectors(vector, 5)
        expect(search_result['results'].first['id']).to eq('vec_1')
      end
    end

    context 'when handling rate limits' do
      before do
        stub_request(:post, %r{/vectors/upsert})
          .to_return(
            status: 429,
            body: { error: 'Rate limit exceeded' }.to_json
          )
      end

      it 'raises RateLimitError' do
        expect { client.upsert_vector('vec_1', vector, {}) }.to raise_error(
          Zerodb::BaseService::RateLimitError
        )
      end
    end

    context 'when API is down and retries' do
      before do
        stub_request(:post, %r{/vectors/search})
          .to_timeout.then
          .to_timeout.then
          .to_return(status: 200, body: { results: [] }.to_json)
      end

      it 'retries and succeeds' do
        result = client.search_vectors(vector, 5)
        expect(result).to have_key('results')
      end
    end
  end
end
