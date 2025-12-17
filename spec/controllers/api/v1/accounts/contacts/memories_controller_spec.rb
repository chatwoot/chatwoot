# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Memories API', type: :request do
  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/memories' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/memories" }
    let(:zerodb_endpoint) { "/#{project_id}/database/memory" }

    context 'when user is unauthenticated' do
      it 'returns unauthorized' do
        get endpoint

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      let(:memories_response) do
        {
          memories: [
            {
              id: 'mem-1',
              content: 'Customer prefers email',
              metadata: { contact_id: contact.id, importance: 'high' }
            },
            {
              id: 'mem-2',
              content: 'Customer timezone is EST',
              metadata: { contact_id: contact.id, importance: 'medium' }
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{api_url}#{zerodb_endpoint}")
          .with(
            query: hash_including(
              contact_id: contact.id,
              account_id: account.id,
              limit: 10
            )
          )
          .to_return(status: 200, body: memories_response.to_json)
      end

      it 'returns all memories for the contact' do
        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body).to be_an(Array)
        expect(body.length).to eq(2)
        expect(body.first['id']).to eq('mem-1')
        expect(body.first['content']).to eq('Customer prefers email')
        expect(body.last['id']).to eq('mem-2')
      end

      it 'calls ZeroDB API with correct parameters' do
        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(WebMock).to have_requested(:get, "#{api_url}#{zerodb_endpoint}")
          .with(query: hash_including(
                  contact_id: contact.id,
                  account_id: account.id
                ))
      end
    end

    context 'with custom limit parameter' do
      before do
        stub_request(:get, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: { memories: [] }.to_json)
      end

      it 'respects limit parameter' do
        get endpoint,
            params: { limit: 5 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(WebMock).to have_requested(:get, "#{api_url}#{zerodb_endpoint}")
          .with(query: hash_including(limit: 5))
      end

      it 'uses default limit when not specified' do
        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(WebMock).to have_requested(:get, "#{api_url}#{zerodb_endpoint}")
          .with(query: hash_including(limit: 10))
      end
    end

    context 'with semantic search query' do
      let(:search_endpoint) { "/#{project_id}/database/memory/search" }
      let(:search_response) do
        {
          results: [
            {
              id: 'mem-3',
              content: 'Customer likes email updates',
              similarity_score: 0.95
            }
          ]
        }
      end

      before do
        stub_request(:post, "#{api_url}#{search_endpoint}")
          .to_return(status: 200, body: search_response.to_json)
      end

      it 'performs semantic search when query is provided' do
        get endpoint,
            params: { query: 'email preferences' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body.first['id']).to eq('mem-3')
        expect(body.first['similarity_score']).to eq(0.95)
      end

      it 'calls search endpoint with query' do
        get endpoint,
            params: { query: 'email preferences' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
      end
    end

    context 'when no memories exist' do
      before do
        stub_request(:get, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: { memories: [] }.to_json)
      end

      it 'returns empty array' do
        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body).to eq([])
      end
    end

    context 'when ZeroDB API fails' do
      before do
        stub_request(:get, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 500, body: { error: 'Internal server error' }.to_json)
      end

      it 'propagates the error' do
        expect {
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json
        }.to raise_error(Zerodb::BaseService::ZeroDBError)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/{contact.id}/memories' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/memories" }
    let(:zerodb_endpoint) { "/#{project_id}/database/memory" }

    context 'when user is unauthenticated' do
      it 'returns unauthorized' do
        post endpoint,
             params: { content: 'Test memory' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      let(:memory_content) { 'Customer prefers phone calls in the morning' }
      let(:importance) { 'high' }
      let(:tags) { %w[preference communication] }
      let(:response_body) do
        {
          id: 'mem-new-123',
          content: memory_content,
          metadata: {
            contact_id: contact.id,
            account_id: account.id,
            importance: importance
          }
        }
      end

      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'creates a new memory successfully' do
        post endpoint,
             params: {
               content: memory_content,
               importance: importance,
               tags: tags
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body['id']).to eq('mem-new-123')
        expect(body['content']).to eq(memory_content)
      end

      it 'sends correct data to ZeroDB API' do
        post endpoint,
             params: {
               content: memory_content,
               importance: importance,
               tags: tags
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(WebMock).to have_requested(:post, "#{api_url}#{zerodb_endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['content'] == memory_content &&
            body['tags'] == tags &&
            body['metadata']['contact_id'] == contact.id &&
            body['metadata']['account_id'] == account.id &&
            body['metadata']['importance'] == importance
          }
      end
    end

    context 'with default importance' do
      let(:response_body) { { id: 'mem-456', content: 'Test content' } }

      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'uses medium as default importance' do
        post endpoint,
             params: { content: 'Test content' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(WebMock).to have_requested(:post, "#{api_url}#{zerodb_endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['metadata']['importance'] == 'medium'
          }
      end
    end

    context 'with empty tags' do
      let(:response_body) { { id: 'mem-789', content: 'Test content' } }

      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'uses empty array for tags by default' do
        post endpoint,
             params: { content: 'Test content' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(WebMock).to have_requested(:post, "#{api_url}#{zerodb_endpoint}")
          .with { |req|
            body = JSON.parse(req.body)
            body['tags'] == []
          }
      end
    end

    context 'with all importance levels' do
      let(:response_body) { { id: 'mem-importance', content: 'Test' } }

      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'accepts low importance' do
        post endpoint,
             params: { content: 'Test', importance: 'low' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'accepts medium importance' do
        post endpoint,
             params: { content: 'Test', importance: 'medium' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'accepts high importance' do
        post endpoint,
             params: { content: 'Test', importance: 'high' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid importance level' do
      it 'returns unprocessable entity error' do
        post endpoint,
             params: { content: 'Test memory', importance: 'critical' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('Invalid importance level')
      end
    end

    context 'with blank content' do
      it 'returns unprocessable entity error' do
        post endpoint,
             params: { content: '' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('content cannot be blank')
      end
    end

    context 'with content too long' do
      it 'returns unprocessable entity error' do
        post endpoint,
             params: { content: 'a' * 5001 },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('too long')
      end
    end

    context 'when ZeroDB API returns authentication error' do
      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 401, body: { error: 'Invalid API key' }.to_json)
      end

      it 'returns bad gateway status' do
        post endpoint,
             params: { content: 'Test memory' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_gateway)
        body = JSON.parse(response.body)
        expect(body['error']).to include('Failed to store memory')
      end
    end

    context 'when ZeroDB API returns validation error' do
      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 422, body: { error: 'Invalid payload' }.to_json)
      end

      it 'returns bad gateway status' do
        post endpoint,
             params: { content: 'Test memory' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_gateway)
        body = JSON.parse(response.body)
        expect(body['error']).to include('Failed to store memory')
      end
    end

    context 'when ZeroDB API returns server error' do
      before do
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 500, body: { error: 'Internal server error' }.to_json)
      end

      it 'returns bad gateway status' do
        post endpoint,
             params: { content: 'Test memory' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_gateway)
        body = JSON.parse(response.body)
        expect(body['error']).to include('Failed to store memory')
      end
    end
  end

  describe 'integration scenarios' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/memories" }
    let(:zerodb_endpoint) { "/#{project_id}/database/memory" }

    context 'storing and retrieving memories' do
      let(:memory1) { 'Customer prefers morning calls' }
      let(:memory2) { 'Customer has budget of $10k' }

      before do
        # Mock store responses
        stub_request(:post, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: { id: 'mem-1', content: memory1 }.to_json)
          .then.to_return(status: 200, body: { id: 'mem-2', content: memory2 }.to_json)

        # Mock retrieve response
        stub_request(:get, "#{api_url}#{zerodb_endpoint}")
          .to_return(status: 200, body: {
            memories: [
              { id: 'mem-1', content: memory1 },
              { id: 'mem-2', content: memory2 }
            ]
          }.to_json)
      end

      it 'can store and retrieve multiple memories' do
        # Store first memory
        post endpoint,
             params: { content: memory1, importance: 'high' },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:created)

        # Store second memory
        post endpoint,
             params: { content: memory2, importance: 'medium' },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:created)

        # Retrieve all memories
        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)

        body = JSON.parse(response.body)
        expect(body.length).to eq(2)
        expect(body.map { |m| m['content'] }).to contain_exactly(memory1, memory2)
      end
    end
  end
end
