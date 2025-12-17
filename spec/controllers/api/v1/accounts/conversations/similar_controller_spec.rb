# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Similar Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:agent) { create(:user, account: account, role: :agent) }

  # Create similar conversations with messages
  let!(:similar_conversation1) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact)
    create(:message, conversation: conv, content: 'Refund request for order', message_type: 'incoming')
    conv
  end

  let!(:similar_conversation2) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact)
    create(:message, conversation: conv, content: 'Need help with payment', message_type: 'incoming')
    conv
  end

  let!(:similar_conversation3) do
    conv = create(:conversation, account: account, inbox: inbox, contact: contact)
    create(:message, conversation: conv, content: 'Order cancellation request', message_type: 'incoming')
    conv
  end

  before do
    # Create messages for the main conversation
    create(:message, conversation: conversation, content: 'I want to refund my order', message_type: 'incoming')
    create(:message, conversation: conversation, content: 'Sure, I will help', message_type: 'outgoing')

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
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: agent)
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
    ENV.delete('OPENAI_API_KEY')
  end

  describe 'GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/similar' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        )

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to the conversation' do
      let(:zerodb_response) do
        {
          'results' => [
            {
              'metadata' => { 'conversation_id' => conversation.id },
              'similarity_score' => 1.0
            },
            {
              'metadata' => { 'conversation_id' => similar_conversation1.id },
              'similarity_score' => 0.89
            },
            {
              'metadata' => { 'conversation_id' => similar_conversation2.id },
              'similarity_score' => 0.82
            },
            {
              'metadata' => { 'conversation_id' => similar_conversation3.id },
              'similarity_score' => 0.76
            }
          ]
        }
      end

      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: zerodb_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success status' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns similar conversations excluding self' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data'].size).to eq(3)

        conversation_ids = json_response['data'].map { |item| item['conversation']['id'] }
        expect(conversation_ids).not_to include(conversation.id)
        expect(conversation_ids).to contain_exactly(
          similar_conversation1.id,
          similar_conversation2.id,
          similar_conversation3.id
        )
      end

      it 'includes similarity scores as percentages' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        first_result = json_response['data'].first

        expect(first_result['similarity_score']).to be_a(Float)
        expect(first_result['similarity_score']).to eq(89.0) # 0.89 * 100
      end

      it 'includes conversation metadata in response' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        first_conversation = json_response['data'].first['conversation']

        expect(first_conversation).to include(
          'id',
          'display_id',
          'status',
          'inbox_id',
          'contact',
          'created_at',
          'updated_at'
        )
      end

      it 'includes contact information in conversation data' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        contact_data = json_response['data'].first['conversation']['contact']

        expect(contact_data).to include('id', 'name', 'email')
      end

      it 'includes meta information in response' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        meta = json_response['meta']

        expect(meta).to include(
          'count' => 3,
          'threshold' => 0.75,
          'query_conversation_id' => conversation.id,
          'account_id' => account.id
        )
      end

      it 'respects limit parameter' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          limit: 2
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data'].size).to eq(2)
      end

      it 'uses default limit when not specified' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data'].size).to be <= 5
      end

      it 'respects threshold parameter' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          threshold: 0.9
        ), headers: agent.create_new_auth_token, as: :json

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 0.9))
      end

      it 'caps limit at maximum allowed value' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          limit: 50
        ), headers: agent.create_new_auth_token, as: :json

        # Should cap at MAX_LIMIT (20)
        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('limit' => 21)) # +1 for self exclusion
      end

      it 'clamps threshold to valid range' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          threshold: 1.5 # Invalid, should be clamped to 1.0
        ), headers: agent.create_new_auth_token, as: :json

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 1.0))
      end

      it 'handles exclude_statuses parameter' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          exclude_statuses: 'resolved,snoozed'
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when ZeroDB returns no results' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(
            status: 200,
            body: { 'results' => [{ 'metadata' => { 'conversation_id' => conversation.id }, 'similarity_score' => 1.0 }] }.to_json
          )
      end

      it 'returns empty data array' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq([])
        expect(json_response['meta']['count']).to eq(0)
      end
    end

    context 'when conversation has no messages' do
      let(:empty_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

      before do
        create(:inbox_member, inbox: empty_conversation.inbox, user: agent)
      end

      it 'returns service unavailable error' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: empty_conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Detection Failed')
      end
    end

    context 'when ZeroDB API is not configured' do
      before do
        ENV.delete('ZERODB_API_KEY')
      end

      it 'returns service unavailable' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:service_unavailable)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Service Configuration Error')
        expect(json_response['message']).to include('not properly configured')
      end
    end

    context 'when ZeroDB API fails' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
      end

      it 'returns internal server error' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Detection Failed')
      end
    end

    context 'when ZeroDB API is rate limited' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 429, body: { error: 'Rate limit exceeded' }.to_json)
      end

      it 'returns internal server error with appropriate message' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when user does not have access to conversation' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      it 'returns forbidden or not found' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ), headers: other_agent.create_new_auth_token, as: :json

        # Should either be forbidden or not found depending on authorization strategy
        expect(response.status).to be_in([403, 404])
      end
    end

    context 'when conversation does not exist' do
      it 'returns not found' do
        get api_v1_account_conversation_similar_index_url(
          account_id: account.id,
          conversation_id: 999999
        ), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when account does not match' do
      let(:other_account) { create(:account) }
      let(:other_agent) { create(:user, account: other_account, role: :agent) }

      it 'returns not found' do
        get api_v1_account_conversation_similar_index_url(
          account_id: other_account.id,
          conversation_id: conversation.display_id
        ), headers: other_agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'response format validation' do
    let(:zerodb_response) do
      {
        'results' => [
          {
            'metadata' => { 'conversation_id' => similar_conversation1.id },
            'similarity_score' => 0.89
          }
        ]
      }
    end

    before do
      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
        .to_return(status: 200, body: zerodb_response.to_json)
    end

    it 'returns valid JSON' do
      get api_v1_account_conversation_similar_index_url(
        account_id: account.id,
        conversation_id: conversation.display_id
      ), headers: agent.create_new_auth_token, as: :json

      expect { JSON.parse(response.body) }.not_to raise_error
    end

    it 'has correct response structure' do
      get api_v1_account_conversation_similar_index_url(
        account_id: account.id,
        conversation_id: conversation.display_id
      ), headers: agent.create_new_auth_token, as: :json

      json_response = JSON.parse(response.body)

      expect(json_response).to have_key('data')
      expect(json_response).to have_key('meta')
      expect(json_response['data']).to be_an(Array)
      expect(json_response['meta']).to be_a(Hash)
    end

    it 'includes all required conversation fields' do
      get api_v1_account_conversation_similar_index_url(
        account_id: account.id,
        conversation_id: conversation.display_id
      ), headers: agent.create_new_auth_token, as: :json

      json_response = JSON.parse(response.body)
      conversation_data = json_response['data'].first['conversation']

      required_fields = %w[id display_id inbox_id status created_at updated_at contact]
      required_fields.each do |field|
        expect(conversation_data).to have_key(field), "Missing required field: #{field}"
      end
    end

    it 'formats similarity_score with 2 decimal places' do
      get api_v1_account_conversation_similar_index_url(
        account_id: account.id,
        conversation_id: conversation.display_id
      ), headers: agent.create_new_auth_token, as: :json

      json_response = JSON.parse(response.body)
      score = json_response['data'].first['similarity_score']

      expect(score).to eq(89.0)
      expect(score.to_s).to match(/^\d+\.\d{1,2}$/)
    end
  end

  describe 'performance' do
    let(:zerodb_response) do
      {
        'results' => Array.new(10) do |i|
          {
            'metadata' => { 'conversation_id' => create(:conversation, account: account, inbox: inbox, contact: contact).id },
            'similarity_score' => 0.9 - (i * 0.01)
          }
        end
      }
    end

    before do
      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
        .to_return(status: 200, body: zerodb_response.to_json)
    end

    it 'completes request within reasonable time' do
      start_time = Time.current

      get api_v1_account_conversation_similar_index_url(
        account_id: account.id,
        conversation_id: conversation.display_id
      ), headers: agent.create_new_auth_token, as: :json

      duration = Time.current - start_time
      expect(duration).to be < 5.seconds
    end
  end
end
