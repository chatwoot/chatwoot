# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::AgentMemoryService, type: :service do
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }
  let(:account_id) { 1 }
  let(:contact_id) { 100 }
  let(:service) { described_class.new(account_id) }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#initialize' do
    it 'initializes with account_id' do
      expect { service }.not_to raise_error
    end

    it 'inherits from BaseService' do
      expect(service).to be_a(Zerodb::BaseService)
    end
  end

  describe '#store_memory' do
    let(:content) { 'Customer prefers email communication' }
    let(:importance) { 'medium' }
    let(:tags) { ['preference', 'communication'] }
    let(:endpoint) { "/#{project_id}/database/memory" }

    context 'with valid parameters' do
      let(:expected_payload) do
        {
          content: content,
          metadata: {
            contact_id: contact_id,
            account_id: account_id,
            importance: importance,
            stored_at: kind_of(String)
          },
          tags: tags
        }
      end

      let(:response_body) do
        {
          id: 'mem-123',
          content: content,
          metadata: {
            contact_id: contact_id,
            account_id: account_id,
            importance: importance
          }
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .with(
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            },
            body: hash_including(
              content: content,
              tags: tags,
              metadata: hash_including(
                contact_id: contact_id,
                account_id: account_id,
                importance: importance
              )
            )
          )
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'stores memory successfully' do
        result = service.store_memory(contact_id, content, importance: importance, tags: tags)
        expect(result['id']).to eq('mem-123')
        expect(result['content']).to eq(content)
      end

      it 'sends correct payload to API' do
        service.store_memory(contact_id, content, importance: importance, tags: tags)

        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['content'] == content &&
            body['tags'] == tags &&
            body['metadata']['contact_id'] == contact_id &&
            body['metadata']['account_id'] == account_id &&
            body['metadata']['importance'] == importance
          }
      end
    end

    context 'with default parameters' do
      let(:response_body) { { id: 'mem-456', content: content } }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'uses default importance of medium' do
        service.store_memory(contact_id, content)

        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['metadata']['importance'] == 'medium'
          }
      end

      it 'uses empty array for tags by default' do
        service.store_memory(contact_id, content)

        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['tags'] == []
          }
      end
    end

    context 'with different importance levels' do
      let(:response_body) { { id: 'mem-789', content: content } }

      before do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'accepts low importance' do
        expect { service.store_memory(contact_id, content, importance: 'low') }.not_to raise_error
      end

      it 'accepts medium importance' do
        expect { service.store_memory(contact_id, content, importance: 'medium') }.not_to raise_error
      end

      it 'accepts high importance' do
        expect { service.store_memory(contact_id, content, importance: 'high') }.not_to raise_error
      end
    end

    context 'with invalid importance level' do
      it 'raises ArgumentError for invalid importance' do
        expect { service.store_memory(contact_id, content, importance: 'critical') }.to raise_error(
          ArgumentError,
          'Invalid importance level: critical. Must be one of: low, medium, high'
        )
      end

      it 'raises ArgumentError for empty importance' do
        expect { service.store_memory(contact_id, content, importance: '') }.to raise_error(
          ArgumentError,
          /Invalid importance level/
        )
      end
    end

    context 'with invalid content' do
      it 'raises ArgumentError when content is blank' do
        expect { service.store_memory(contact_id, '') }.to raise_error(
          ArgumentError,
          'Memory content cannot be blank'
        )
      end

      it 'raises ArgumentError when content is nil' do
        expect { service.store_memory(contact_id, nil) }.to raise_error(
          ArgumentError,
          'Memory content cannot be blank'
        )
      end

      it 'raises ArgumentError when content is too long' do
        long_content = 'a' * 5001
        expect { service.store_memory(contact_id, long_content) }.to raise_error(
          ArgumentError,
          'Memory content is too long (max 5000 characters)'
        )
      end

      it 'accepts content at maximum length' do
        max_content = 'a' * 5000
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 200, body: { id: 'mem-max', content: max_content }.to_json)

        expect { service.store_memory(contact_id, max_content) }.not_to raise_error
      end
    end

    context 'when API returns error' do
      it 'raises AuthenticationError on 401' do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 401, body: { error: 'Invalid API key' }.to_json)

        expect { service.store_memory(contact_id, content) }.to raise_error(
          Zerodb::BaseService::AuthenticationError
        )
      end

      it 'raises ValidationError on 422' do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 422, body: { error: 'Invalid payload' }.to_json)

        expect { service.store_memory(contact_id, content) }.to raise_error(
          Zerodb::BaseService::ValidationError
        )
      end

      it 'raises ZeroDBError on 500' do
        stub_request(:post, "#{api_url}#{endpoint}")
          .to_return(status: 500, body: { error: 'Internal server error' }.to_json)

        expect { service.store_memory(contact_id, content) }.to raise_error(
          Zerodb::BaseService::ZeroDBError
        )
      end
    end
  end

  describe '#recall_memories' do
    let(:endpoint_list) { "/#{project_id}/database/memory" }
    let(:endpoint_search) { "/#{project_id}/database/memory/search" }

    context 'listing memories without query' do
      let(:memories_response) do
        {
          memories: [
            {
              id: 'mem-1',
              content: 'Customer prefers phone calls',
              metadata: { contact_id: contact_id, importance: 'high' }
            },
            {
              id: 'mem-2',
              content: 'Customer timezone is EST',
              metadata: { contact_id: contact_id, importance: 'medium' }
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .with(
            query: hash_including(
              contact_id: contact_id,
              account_id: account_id,
              limit: 10
            )
          )
          .to_return(status: 200, body: memories_response.to_json)
      end

      it 'retrieves all memories for contact' do
        result = service.recall_memories(contact_id)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first['id']).to eq('mem-1')
        expect(result.last['id']).to eq('mem-2')
      end

      it 'includes contact_id in query parameters' do
        service.recall_memories(contact_id)

        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint_list}")
          .with(query: hash_including(contact_id: contact_id))
      end

      it 'includes account_id in query parameters' do
        service.recall_memories(contact_id)

        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint_list}")
          .with(query: hash_including(account_id: account_id))
      end
    end

    context 'with custom limit' do
      before do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .to_return(status: 200, body: { memories: [] }.to_json)
      end

      it 'respects custom limit parameter' do
        service.recall_memories(contact_id, limit: 5)

        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint_list}")
          .with(query: hash_including(limit: 5))
      end

      it 'uses default limit of 10' do
        service.recall_memories(contact_id)

        expect(WebMock).to have_requested(:get, "#{api_url}#{endpoint_list}")
          .with(query: hash_including(limit: 10))
      end
    end

    context 'semantic search with query' do
      let(:query) { 'communication preferences' }
      let(:search_response) do
        {
          results: [
            {
              id: 'mem-3',
              content: 'Customer prefers email communication',
              metadata: { contact_id: contact_id },
              similarity_score: 0.95
            }
          ]
        }
      end

      before do
        stub_request(:post, "#{api_url}#{endpoint_search}")
          .with(
            body: hash_including(
              query: query,
              limit: 10,
              filter_metadata: hash_including(
                contact_id: contact_id,
                account_id: account_id
              )
            )
          )
          .to_return(status: 200, body: search_response.to_json)
      end

      it 'performs semantic search when query is provided' do
        result = service.recall_memories(contact_id, query: query)
        expect(result).to be_an(Array)
        expect(result.first['id']).to eq('mem-3')
        expect(result.first['similarity_score']).to eq(0.95)
      end

      it 'sends query in request body' do
        service.recall_memories(contact_id, query: query)

        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint_search}")
          .with { |req|
            body = JSON.parse(req.body)
            body['query'] == query
          }
      end

      it 'includes filter metadata in search' do
        service.recall_memories(contact_id, query: query)

        expect(WebMock).to have_requested(:post, "#{api_url}#{endpoint_search}")
          .with { |req|
            body = JSON.parse(req.body)
            body['filter_metadata']['contact_id'] == contact_id &&
            body['filter_metadata']['account_id'] == account_id
          }
      end
    end

    context 'when API returns empty results' do
      it 'returns empty array for list endpoint' do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .to_return(status: 200, body: { memories: [] }.to_json)

        result = service.recall_memories(contact_id)
        expect(result).to eq([])
      end

      it 'returns empty array for search endpoint' do
        stub_request(:post, "#{api_url}#{endpoint_search}")
          .to_return(status: 200, body: { results: [] }.to_json)

        result = service.recall_memories(contact_id, query: 'test')
        expect(result).to eq([])
      end
    end

    context 'when API response has alternate field names' do
      it 'handles "results" field from search' do
        stub_request(:post, "#{api_url}#{endpoint_search}")
          .to_return(status: 200, body: { results: [{ id: 'mem-x', content: 'test' }] }.to_json)

        result = service.recall_memories(contact_id, query: 'test')
        expect(result.first['id']).to eq('mem-x')
      end

      it 'handles "memories" field from list' do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .to_return(status: 200, body: { memories: [{ id: 'mem-y', content: 'test' }] }.to_json)

        result = service.recall_memories(contact_id)
        expect(result.first['id']).to eq('mem-y')
      end
    end

    context 'when API returns error' do
      it 'raises AuthenticationError on 401' do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json)

        expect { service.recall_memories(contact_id) }.to raise_error(
          Zerodb::BaseService::AuthenticationError
        )
      end

      it 'raises ZeroDBError on 500' do
        stub_request(:get, "#{api_url}#{endpoint_list}")
          .to_return(status: 500, body: { error: 'Server error' }.to_json)

        expect { service.recall_memories(contact_id) }.to raise_error(
          Zerodb::BaseService::ZeroDBError
        )
      end
    end
  end

  describe 'importance level validation' do
    it 'defines valid importance levels' do
      expect(described_class::VALID_IMPORTANCE_LEVELS).to eq(%w[low medium high])
    end
  end

  describe 'integration scenarios' do
    context 'storing and recalling memories' do
      let(:content1) { 'Customer prefers morning calls' }
      let(:content2) { 'Customer has budget of $10k' }

      before do
        # Store memory 1
        stub_request(:post, "#{api_url}/#{project_id}/database/memory")
          .to_return(status: 200, body: { id: 'mem-1', content: content1 }.to_json)

        # Store memory 2
        stub_request(:post, "#{api_url}/#{project_id}/database/memory")
          .to_return(status: 200, body: { id: 'mem-2', content: content2 }.to_json)

        # Recall memories
        stub_request(:get, "#{api_url}/#{project_id}/database/memory")
          .to_return(status: 200, body: {
            memories: [
              { id: 'mem-1', content: content1 },
              { id: 'mem-2', content: content2 }
            ]
          }.to_json)
      end

      it 'can store multiple memories and retrieve them' do
        service.store_memory(contact_id, content1, importance: 'high')
        service.store_memory(contact_id, content2, importance: 'medium')

        memories = service.recall_memories(contact_id)
        expect(memories.length).to eq(2)
      end
    end
  end
end
