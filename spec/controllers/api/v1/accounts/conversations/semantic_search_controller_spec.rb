# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Semantic Search API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  # Create test conversations with messages
  let!(:conversation1) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact, status: :open)
    create(:message, conversation: conv, content: 'I need a refund for my order', message_type: 'incoming')
    create(:message, conversation: conv, content: 'Let me help you with that', message_type: 'outgoing')
    conv
  end

  let!(:conversation2) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact, status: :open)
    create(:message, conversation: conv, content: 'How do I track my shipment?', message_type: 'incoming')
    conv
  end

  let!(:conversation3) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact, status: :resolved)
    create(:message, conversation: conv, content: 'Payment issue with credit card', message_type: 'incoming')
    conv
  end

  # Conversation from different account for isolation testing
  let(:other_account) { create(:account) }
  let(:other_inbox) { create(:inbox, account: other_account) }
  let!(:other_account_conversation) do
    conv = create(:conversation, account: other_account, inbox: other_inbox)
    create(:message, conversation: conv, content: 'This should not be returned', message_type: 'incoming')
    conv
  end

  before do
    # Set up environment for ZeroDB
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project'
    ENV['OPENAI_API_KEY'] = 'test-openai-key'

    # Stub OpenAI embedding generation
    mock_embedding = Array.new(1536) { rand }
    openai_client = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(openai_client).to receive(:embeddings).and_return(
      { 'data' => [{ 'embedding' => mock_embedding }] }
    )

    # Create inbox member so agent has access
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: admin)
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
    ENV.delete('OPENAI_API_KEY')
  end

  describe 'POST /api/v1/accounts/{account_id}/conversations/semantic_search' do
    let(:search_params) do
      {
        query: 'refund request',
        limit: 10
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:zerodb_search_response) do
        {
          'results' => [
            {
              'metadata' => {
                'conversation_id' => conversation1.id,
                'account_id' => account.id,
                'inbox_id' => inbox.id,
                'status' => 'open'
              },
              'similarity_score' => 0.92
            },
            {
              'metadata' => {
                'conversation_id' => conversation2.id,
                'account_id' => account.id,
                'inbox_id' => inbox.id,
                'status' => 'open'
              },
              'similarity_score' => 0.78
            }
          ]
        }
      end

      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: zerodb_search_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success status' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns search results in correct format' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('data')
        expect(json_response).to have_key('meta')
        expect(json_response['meta']).to have_key('total_count')
        expect(json_response['meta']).to have_key('query')
        expect(json_response['meta']).to have_key('limit')
        expect(json_response['meta']).to have_key('account_id')
      end

      it 'returns conversations matching search query' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data'].size).to eq(2)

        conversation_ids = json_response['data'].map { |item| item['id'] }
        expect(conversation_ids).to contain_exactly(conversation1.id, conversation2.id)
      end

      it 'includes conversation details in response' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        first_result = json_response['data'].first

        expect(first_result).to have_key('id')
        expect(first_result).to have_key('display_id')
        expect(first_result).to have_key('inbox_id')
        expect(first_result).to have_key('status')
        expect(first_result).to have_key('contact')
        expect(first_result).to have_key('assignee')
        expect(first_result).to have_key('messages_count')
        expect(first_result).to have_key('labels')
      end

      it 'respects the limit parameter' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(limit: 1), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['meta']['limit']).to eq(1)
      end

      it 'uses default limit when not provided' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: { query: 'test' }, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['meta']['limit']).to eq(20)
      end

      it 'clamps limit to maximum of 100' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(limit: 500), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['meta']['limit']).to eq(100)
      end

      it 'clamps limit to minimum of 1' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(limit: -5), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['meta']['limit']).to eq(1)
      end

      it 'filters by status when provided' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(status: 'open'), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        # Verify the request was made with correct filters
        expect(WebMock).to have_requested(:post, %r{vectors/search})
      end

      it 'filters by inbox_id when provided' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(inbox_id: inbox.id), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'filters by assignee_id when provided' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params.merge(assignee_id: agent.id), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'only returns conversations from the current account' do
        # Mock response that includes conversations from different accounts
        mixed_response = {
          'results' => [
            {
              'metadata' => {
                'conversation_id' => conversation1.id,
                'account_id' => account.id
              }
            },
            {
              'metadata' => {
                'conversation_id' => other_account_conversation.id,
                'account_id' => other_account.id
              }
            }
          ]
        }

        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: mixed_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        # Should only return conversation from current account
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['id']).to eq(conversation1.id)
      end
    end

    context 'when query parameter is missing' do
      it 'returns unprocessable entity with error message' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: { limit: 10 }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'when query parameter is blank' do
      it 'returns validation error' do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 422,
            body: { error: 'Query cannot be blank' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: { query: '' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Validation Error')
      end
    end

    context 'when ZeroDB service returns network error' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_timeout
      end

      it 'returns service unavailable status' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Service Unavailable')
      end
    end

    context 'when ZeroDB service returns rate limit error' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 429,
            body: { error: 'Rate limit exceeded' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns too many requests status' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:too_many_requests)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Rate Limit Exceeded')
      end
    end

    context 'when ZeroDB service returns authentication error' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 401,
            body: { error: 'Invalid API key' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns service unavailable status' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Service Configuration Error')
      end
    end

    context 'when ZeroDB service returns server error' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 500,
            body: { error: 'Internal server error' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns internal server error status' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Search Failed')
      end
    end

    context 'when user does not have access to account' do
      let(:other_user) { create(:user, account: other_account, role: :agent) }

      it 'returns unauthorized' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: other_user.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no conversations match the search' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: { 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns empty results' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to be_empty
        expect(json_response['meta']['total_count']).to eq(0)
      end
    end

    context 'when search returns conversations with missing metadata' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: {
              'results' => [
                { 'metadata' => {} }, # Missing conversation_id
                { 'metadata' => { 'conversation_id' => conversation1.id } }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'filters out results with missing conversation_id' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['id']).to eq(conversation1.id)
      end
    end

    context 'when OpenAI API fails to generate embedding' do
      before do
        openai_client = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(openai_client)
        allow(openai_client).to receive(:embeddings).and_raise(StandardError.new('OpenAI API error'))
      end

      it 'returns internal server error' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'authorization checks' do
      it 'allows agents to search conversations' do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: { 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'allows administrators to search conversations' do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: { 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: search_params, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with multiple filters applied' do
      it 'applies all filters correctly' do
        post api_v1_account_conversation_semantic_search_url(
          account_id: account.id
        ), params: {
          query: 'refund',
          limit: 5,
          status: 'open',
          inbox_id: inbox.id,
          assignee_id: agent.id
        }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
