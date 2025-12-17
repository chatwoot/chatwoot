# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Canned Response Suggestions API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe 'GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/canned_response_suggestions' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/canned_response_suggestions" }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get endpoint

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:canned_response_1) { create(:canned_response, account: account, short_code: 'greeting', content: 'Hello! How can I help?') }
      let!(:canned_response_2) { create(:canned_response, account: account, short_code: 'thanks', content: 'Thank you for contacting us') }
      let(:query_vector) { Array.new(1536) { rand } }
      let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }
      let(:search_endpoint) { "/#{project_id}/vectors/search" }

      before do
        # Create customer messages
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello', created_at: 2.minutes.ago)
        create(:message, conversation: conversation, message_type: :incoming, content: 'I need help', created_at: 1.minute.ago)
      end

      context 'when suggestions are found' do
        let(:search_results) do
          {
            'results' => [
              {
                'id' => "canned_response_#{account.id}_#{canned_response_1.id}",
                'score' => 0.92,
                'metadata' => {
                  'canned_response_id' => canned_response_1.id,
                  'account_id' => account.id,
                  'short_code' => 'greeting',
                  'content' => 'Hello! How can I help?'
                }
              },
              {
                'id' => "canned_response_#{account.id}_#{canned_response_2.id}",
                'score' => 0.85,
                'metadata' => {
                  'canned_response_id' => canned_response_2.id,
                  'account_id' => account.id,
                  'short_code' => 'thanks',
                  'content' => 'Thank you for contacting us'
                }
              }
            ],
            'count' => 2
          }
        end

        before do
          # Stub embedding generation
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(
              status: 200,
              body: { embedding: query_vector, dimension: 1536 }.to_json
            )

          # Stub vector search
          stub_request(:post, "#{api_url}#{search_endpoint}")
            .to_return(status: 200, body: search_results.to_json)
        end

        it 'returns AI-powered suggestions' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
        end

        it 'includes suggestions array in response' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['suggestions']).to be_present
          expect(parsed_response['suggestions'].length).to eq(2)
        end

        it 'includes metadata in response' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['meta']).to include(
            'count' => 2,
            'conversation_id' => conversation.id,
            'powered_by' => 'ZeroDB AI'
          )
        end

        it 'respects custom limit parameter' do
          get endpoint,
              params: { limit: 3 },
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
          expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
            .with(body: hash_including('limit' => 3))
        end

        it 'caps limit at 20 suggestions' do
          get endpoint,
              params: { limit: 100 },
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
          expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
            .with(body: hash_including('limit' => 20))
        end

        it 'uses default limit of 5 when not specified' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
          expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
            .with(body: hash_including('limit' => 5))
        end
      end

      context 'when no suggestions are found' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(status: 200, body: { embedding: query_vector }.to_json)

          stub_request(:post, "#{api_url}#{search_endpoint}")
            .to_return(status: 200, body: { results: [], count: 0 }.to_json)
        end

        it 'returns empty suggestions array' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
          parsed_response = response.parsed_body
          expect(parsed_response['suggestions']).to eq([])
          expect(parsed_response['meta']['count']).to eq(0)
        end
      end

      context 'when conversation has no customer messages' do
        let(:empty_conversation) { create(:conversation, account: account) }
        let(:empty_endpoint) { "/api/v1/accounts/#{account.id}/conversations/#{empty_conversation.id}/canned_response_suggestions" }

        it 'returns empty suggestions' do
          get empty_endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:ok)
          parsed_response = response.parsed_body
          expect(parsed_response['suggestions']).to eq([])
        end

        it 'does not call ZeroDB API' do
          get empty_endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(WebMock).not_to have_requested(:post, "#{api_url}#{generate_endpoint}")
          expect(WebMock).not_to have_requested(:post, "#{api_url}#{search_endpoint}")
        end
      end
    end

    context 'when ZeroDB API fails' do
      let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }

      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
      end

      context 'with authentication error' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(
              status: 401,
              body: { error: 'Invalid API key' }.to_json
            )
        end

        it 'returns unauthorized status' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unauthorized)
        end

        it 'includes error message' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['error']).to eq('AI suggestions temporarily unavailable')
          expect(parsed_response['suggestions']).to eq([])
        end
      end

      context 'with rate limit error' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(
              status: 429,
              body: { error: 'Rate limit exceeded' }.to_json
            )
        end

        it 'returns too many requests status' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:too_many_requests)
        end

        it 'includes error message and empty suggestions' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['error']).to eq('AI suggestions temporarily unavailable')
          expect(parsed_response['suggestions']).to eq([])
        end
      end

      context 'with validation error' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(
              status: 422,
              body: { error: 'Invalid request' }.to_json
            )
        end

        it 'returns unprocessable entity status' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with server error' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_return(
              status: 500,
              body: { error: 'Internal server error' }.to_json
            )
        end

        it 'returns service unavailable status' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:service_unavailable)
        end

        it 'includes error message' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['error']).to eq('AI suggestions temporarily unavailable')
          expect(parsed_response['suggestions']).to eq([])
        end
      end

      context 'with network timeout' do
        before do
          stub_request(:post, "#{api_url}#{generate_endpoint}")
            .to_timeout
        end

        it 'returns internal server error status' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:internal_server_error)
        end

        it 'includes generic error message' do
          get endpoint,
              headers: agent.create_new_auth_token,
              as: :json

          parsed_response = response.parsed_body
          expect(parsed_response['error']).to eq('Failed to fetch suggestions')
          expect(parsed_response['suggestions']).to eq([])
        end
      end
    end

    context 'when conversation does not exist' do
      let(:invalid_endpoint) { "/api/v1/accounts/#{account.id}/conversations/99999/canned_response_suggestions" }

      it 'returns not found' do
        get invalid_endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user does not have access to conversation' do
      let(:other_account) { create(:account) }
      let(:other_conversation) { create(:conversation, account: other_account) }
      let(:unauthorized_endpoint) { "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.id}/canned_response_suggestions" }

      it 'returns not found' do
        get unauthorized_endpoint,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'error logging' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/canned_response_suggestions" }
    let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }

    before do
      create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
    end

    context 'when ZeroDB error occurs' do
      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_return(
            status: 500,
            body: { error: 'Server error' }.to_json
          )
      end

      it 'logs ZeroDB error' do
        expect(Rails.logger).to receive(:error)
          .with(a_string_matching(/\[CannedResponseSuggestions\] ZeroDB error/))

        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow_any_instance_of(Zerodb::CannedResponseSuggester)
          .to receive(:suggest)
          .and_raise(StandardError.new('Unexpected error'))
      end

      it 'logs server error with backtrace' do
        expect(Rails.logger).to receive(:error)
          .with(a_string_matching(/\[CannedResponseSuggestions\] Server error/))
        expect(Rails.logger).to receive(:error)
          .with(kind_of(String)) # backtrace

        get endpoint,
            headers: agent.create_new_auth_token,
            as: :json
      end
    end
  end

  describe 'performance' do
    let(:endpoint) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/canned_response_suggestions" }
    let(:query_vector) { Array.new(1536) { rand } }
    let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }
    let(:search_endpoint) { "/#{project_id}/vectors/search" }

    before do
      create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')

      stub_request(:post, "#{api_url}#{generate_endpoint}")
        .to_return(status: 200, body: { embedding: query_vector }.to_json)

      stub_request(:post, "#{api_url}#{search_endpoint}")
        .to_return(status: 200, body: { results: [], count: 0 }.to_json)
    end

    it 'responds within acceptable time' do
      start_time = Time.current

      get endpoint,
          headers: agent.create_new_auth_token,
          as: :json

      duration = Time.current - start_time
      expect(duration).to be < 5.0 # Should respond in less than 5 seconds
    end
  end
end
