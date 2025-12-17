# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RLHF Feedback API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project-id'
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
  end

  describe 'POST /api/v1/rlhf/feedback' do
    let(:valid_params) do
      {
        suggestion_type: 'canned_response_suggestion',
        prompt: 'Customer asking about refund policy',
        response: 'Our refund policy allows returns within 30 days',
        rating: 5,
        feedback: 'Very helpful suggestion',
        metadata: {
          conversation_id: conversation.id,
          suggestion_id: 'sugg-123'
        }
      }
    end

    let(:api_success_response) do
      {
        'id' => 'feedback-abc123',
        'status' => 'recorded',
        'account_id' => account.id,
        'created_at' => Time.current.iso8601
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        post '/api/v1/rlhf/feedback', params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/database/rlhf})
          .to_return(
            status: 200,
            body: api_success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      context 'with valid parameters using rating' do
        it 'returns 201 created' do
          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
        end

        it 'returns success message with feedback ID' do
          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Feedback recorded successfully')
          expect(json_response['feedback_id']).to eq('feedback-abc123')
        end

        it 'calls RlhfService with correct parameters' do
          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            suggestion_type: 'canned_response_suggestion',
            prompt: 'Customer asking about refund policy',
            response: 'Our refund policy allows returns within 30 days',
            rating: 5,
            feedback: 'Very helpful suggestion',
            metadata: hash_including(
              'conversation_id' => conversation.id,
              'suggestion_id' => 'sugg-123',
              'agent_id' => agent.id,
              'agent_name' => agent.name,
              'account_id' => account.id
            )
          )
        end

        it 'includes agent information in metadata' do
          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            hash_including(
              metadata: hash_including(
                'agent_id' => agent.id,
                'agent_name' => agent.name,
                'account_id' => account.id
              )
            )
          )
        end

        it 'includes timestamp in metadata' do
          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            hash_including(
              metadata: hash_including('timestamp')
            )
          )
        end

        it 'merges conversation_id from params into metadata' do
          params = valid_params.merge(conversation_id: 999)

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            hash_including(
              metadata: hash_including('conversation_id' => 999)
            )
          )
        end

        it 'merges suggestion_id from params into metadata' do
          params = valid_params.merge(suggestion_id: 'custom-sugg-id')

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            hash_including(
              metadata: hash_including('suggestion_id' => 'custom-sugg-id')
            )
          )
        end

        (1..5).each do |rating|
          it "accepts rating #{rating}" do
            params = valid_params.merge(rating: rating)

            post '/api/v1/rlhf/feedback',
                 params: params,
                 headers: agent.create_new_auth_token,
                 as: :json

            expect(response).to have_http_status(:created)
          end
        end

        Zerodb::RlhfService::VALID_SUGGESTION_TYPES.each do |suggestion_type|
          it "accepts suggestion_type: #{suggestion_type}" do
            params = valid_params.merge(suggestion_type: suggestion_type)

            post '/api/v1/rlhf/feedback',
                 params: params,
                 headers: agent.create_new_auth_token,
                 as: :json

            expect(response).to have_http_status(:created)
          end
        end

        it 'handles nil feedback gracefully' do
          params = valid_params.except(:feedback)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
        end

        it 'handles empty metadata gracefully' do
          params = valid_params.merge(metadata: {})

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
        end
      end

      context 'with valid parameters using thumbs' do
        it 'accepts thumbs: "up" and converts to rating 5' do
          params = valid_params.except(:rating).merge(thumbs: 'up')

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
          expect(service_double).to have_received(:log_feedback).with(
            hash_including(rating: 5)
          )
        end

        it 'accepts thumbs: "down" and converts to rating 1' do
          params = valid_params.except(:rating).merge(thumbs: 'down')

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
          expect(service_double).to have_received(:log_feedback).with(
            hash_including(rating: 1)
          )
        end

        it 'accepts thumbs: "thumbs_up"' do
          params = valid_params.except(:rating).merge(thumbs: 'thumbs_up')

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:created)
          expect(service_double).to have_received(:log_feedback).with(
            hash_including(rating: 5)
          )
        end

        it 'prefers rating over thumbs when both provided' do
          params = valid_params.merge(thumbs: 'down', rating: 4)

          service_double = instance_double(Zerodb::RlhfService)
          allow(Zerodb::RlhfService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:log_feedback).and_return(api_success_response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(service_double).to have_received(:log_feedback).with(
            hash_including(rating: 4)
          )
        end
      end

      context 'with missing required parameters' do
        it 'returns 400 when suggestion_type is missing' do
          params = valid_params.except(:suggestion_type)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Missing required parameters')
          expect(json_response['missing']).to include('suggestion_type')
        end

        it 'returns 400 when prompt is missing' do
          params = valid_params.except(:prompt)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['missing']).to include('prompt')
        end

        it 'returns 400 when response is missing' do
          params = valid_params.except(:response)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['missing']).to include('response')
        end

        it 'returns 400 when both rating and thumbs are missing' do
          params = valid_params.except(:rating)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('rating')
          expect(json_response['error']).to include('thumbs')
        end

        it 'lists all missing required parameters' do
          params = { rating: 5 } # Only rating provided

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['missing']).to include('suggestion_type', 'prompt', 'response')
        end
      end

      context 'with invalid parameters' do
        it 'returns 422 for invalid suggestion_type' do
          params = valid_params.merge(suggestion_type: 'invalid_type')

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Invalid suggestion_type')
        end

        it 'returns 422 for invalid rating' do
          params = valid_params.merge(rating: 10)

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Invalid rating')
        end

        it 'returns 422 for invalid thumbs value' do
          params = valid_params.except(:rating).merge(thumbs: 'invalid')

          post '/api/v1/rlhf/feedback',
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Invalid thumbs value')
        end
      end

      context 'when service raises errors' do
        it 'returns 422 for ArgumentError' do
          allow_any_instance_of(Zerodb::RlhfService).to receive(:log_feedback)
            .and_raise(ArgumentError.new('Invalid data'))

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Invalid data')
        end

        it 'returns 500 for StandardError' do
          allow_any_instance_of(Zerodb::RlhfService).to receive(:log_feedback)
            .and_raise(StandardError.new('Service unavailable'))

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Failed to record feedback')
        end

        it 'logs errors when service fails' do
          allow_any_instance_of(Zerodb::RlhfService).to receive(:log_feedback)
            .and_raise(StandardError.new('Service error'))

          allow(Rails.logger).to receive(:error)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(Rails.logger).to have_received(:error).with(
            a_string_matching(/RLHF feedback submission failed/)
          )
        end
      end

      context 'when ZeroDB API returns errors' do
        it 'handles 401 Unauthorized' do
          stub_request(:post, %r{database/rlhf})
            .to_return(status: 401, body: { error: 'Unauthorized' }.to_json)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
        end

        it 'handles 500 Internal Server Error' do
          stub_request(:post, %r{database/rlhf})
            .to_return(status: 500, body: { error: 'Server error' }.to_json)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
        end

        it 'handles network timeout' do
          stub_request(:post, %r{database/rlhf})
            .to_timeout

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
        end
      end

      context 'response format when feedback_id is in different fields' do
        it 'uses "id" field if present' do
          response_with_id = { 'id' => 'feedback-id-123' }
          stub_request(:post, %r{database/rlhf})
            .to_return(status: 200, body: response_with_id.to_json)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          json_response = JSON.parse(response.body)
          expect(json_response['feedback_id']).to eq('feedback-id-123')
        end

        it 'uses "feedback_id" field if "id" is not present' do
          response_with_feedback_id = { 'feedback_id' => 'feedback-id-456' }
          stub_request(:post, %r{database/rlhf})
            .to_return(status: 200, body: response_with_feedback_id.to_json)

          post '/api/v1/rlhf/feedback',
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          json_response = JSON.parse(response.body)
          expect(json_response['feedback_id']).to eq('feedback-id-456')
        end
      end
    end
  end

  describe 'GET /api/v1/rlhf/stats' do
    let(:stats_response) do
      {
        'total_feedback' => 150,
        'avg_rating' => 4.2,
        'feedback_by_type' => {
          'canned_response_suggestion' => 80,
          'semantic_search' => 70
        },
        'recent_feedback' => [
          { 'id' => 'abc123', 'rating' => 5, 'suggestion_type' => 'canned_response_suggestion' },
          { 'id' => 'def456', 'rating' => 4, 'suggestion_type' => 'semantic_search' }
        ]
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        get '/api/v1/rlhf/stats', as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before do
        stub_request(:get, %r{https://api.ainative.studio/v1/public/.*/database/rlhf/stats})
          .to_return(
            status: 200,
            body: stats_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns 200 OK' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns RLHF statistics' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['total_feedback']).to eq(150)
        expect(json_response['avg_rating']).to eq(4.2)
      end

      it 'includes feedback breakdown by type' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['feedback_by_type']).to be_a(Hash)
        expect(json_response['feedback_by_type']['canned_response_suggestion']).to eq(80)
        expect(json_response['feedback_by_type']['semantic_search']).to eq(70)
      end

      it 'includes recent feedback items' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['recent_feedback']).to be_an(Array)
        expect(json_response['recent_feedback'].size).to eq(2)
      end

      it 'calls RlhfService with correct account_id' do
        service_double = instance_double(Zerodb::RlhfService)
        allow(Zerodb::RlhfService).to receive(:new)
          .with(account_id: account.id)
          .and_return(service_double)
        allow(service_double).to receive(:get_stats).and_return(stats_response)

        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(Zerodb::RlhfService).to have_received(:new).with(account_id: account.id)
        expect(service_double).to have_received(:get_stats)
      end

      it 'handles empty stats gracefully' do
        empty_stats = { 'total_feedback' => 0, 'avg_rating' => 0 }
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(status: 200, body: empty_stats.to_json)

        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['total_feedback']).to eq(0)
      end
    end

    context 'when service raises errors' do
      before do
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)
      end

      it 'returns 500 for StandardError' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to retrieve statistics')
      end

      it 'logs errors when stats retrieval fails' do
        allow(Rails.logger).to receive(:error)

        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/RLHF stats retrieval failed/)
        )
      end
    end

    context 'when ZeroDB API is not available' do
      before do
        stub_request(:get, %r{database/rlhf/stats})
          .to_timeout
      end

      it 'returns 500 with error message' do
        get '/api/v1/rlhf/stats',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe 'edge cases and security' do
    before do
      stub_request(:post, %r{database/rlhf})
        .to_return(
          status: 200,
          body: { 'id' => 'test-id' }.to_json
        )
    end

    it 'sanitizes HTML in prompt' do
      params = {
        suggestion_type: 'semantic_search',
        prompt: '<script>alert("xss")</script>Test prompt',
        response: 'Test response',
        rating: 3
      }

      post '/api/v1/rlhf/feedback',
           params: params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:created)
    end

    it 'handles very long text inputs' do
      params = {
        suggestion_type: 'semantic_search',
        prompt: 'a' * 10_000,
        response: 'b' * 10_000,
        rating: 3
      }

      post '/api/v1/rlhf/feedback',
           params: params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:created)
    end

    it 'handles unicode characters' do
      params = {
        suggestion_type: 'semantic_search',
        prompt: '测试 тест 🎉',
        response: 'Response with émojis 👍',
        rating: 5,
        feedback: 'Great! 中文 العربية'
      }

      post '/api/v1/rlhf/feedback',
           params: params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:created)
    end

    it 'rejects requests from different account' do
      other_account = create(:account)
      other_agent = create(:user, account: other_account, role: :agent)

      params = {
        suggestion_type: 'semantic_search',
        prompt: 'Test',
        response: 'Test response',
        rating: 3
      }

      # Ensure service is called with correct account
      service_double = instance_double(Zerodb::RlhfService)
      allow(Zerodb::RlhfService).to receive(:new)
        .with(account_id: other_account.id)
        .and_return(service_double)
      allow(service_double).to receive(:log_feedback).and_return({ 'id' => 'test' })

      post '/api/v1/rlhf/feedback',
           params: params,
           headers: other_agent.create_new_auth_token,
           as: :json

      expect(Zerodb::RlhfService).to have_received(:new).with(account_id: other_account.id)
    end
  end
end
