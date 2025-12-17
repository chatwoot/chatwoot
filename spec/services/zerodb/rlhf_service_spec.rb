# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::RlhfService do
  subject(:service) { described_class.new(account_id: account_id) }

  let(:account_id) { 123 }
  let(:base_url) { 'https://api.ainative.studio/v1/public' }

  before do
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project-id'
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
  end

  describe '#initialize' do
    context 'when credentials are missing' do
      it 'raises ConfigurationError when API key is missing' do
        ENV.delete('ZERODB_API_KEY')
        expect { described_class.new(account_id: account_id) }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /ZERODB_API_KEY/
        )
      end

      it 'raises ConfigurationError when project ID is missing' do
        ENV.delete('ZERODB_PROJECT_ID')
        expect { described_class.new(account_id: account_id) }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /ZERODB_PROJECT_ID/
        )
      end
    end

    context 'when credentials are present' do
      it 'initializes successfully' do
        expect { described_class.new(account_id: account_id) }.not_to raise_error
      end

      it 'stores the account_id' do
        service = described_class.new(account_id: 456)
        expect(service.instance_variable_get(:@account_id)).to eq(456)
      end
    end
  end

  describe '#log_feedback' do
    let(:valid_params) do
      {
        suggestion_type: 'canned_response_suggestion',
        prompt: 'Customer asking about refund policy',
        response: 'Our refund policy allows returns within 30 days',
        rating: 5,
        feedback: 'Very helpful suggestion',
        metadata: { conversation_id: 789 }
      }
    end

    let(:api_success_response) do
      {
        'id' => 'feedback-abc123',
        'status' => 'recorded',
        'account_id' => account_id,
        'created_at' => Time.current.iso8601
      }
    end

    context 'with valid parameters' do
      before do
        stub_request(:post, %r{#{base_url}/test-project-id/database/rlhf})
          .to_return(
            status: 200,
            body: api_success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'successfully logs feedback' do
        result = service.log_feedback(**valid_params)

        expect(result).to be_a(Hash)
        expect(result['id']).to eq('feedback-abc123')
        expect(result['status']).to eq('recorded')
      end

      it 'sends correct request to ZeroDB API' do
        service.log_feedback(**valid_params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'X-Project-ID' => 'test-project-id'
            },
            body: hash_including(
              'interaction_type' => 'canned_response_suggestion',
              'prompt' => 'Customer asking about refund policy',
              'response' => 'Our refund policy allows returns within 30 days',
              'rating' => 5,
              'feedback' => 'Very helpful suggestion'
            )
          )
      end

      it 'includes account_id in metadata' do
        service.log_feedback(**valid_params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including(
            'metadata' => hash_including('account_id' => account_id)
          ))
      end

      it 'includes timestamp in metadata' do
        service.log_feedback(**valid_params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including(
            'metadata' => hash_including('timestamp')
          ))
      end

      it 'merges provided metadata with system metadata' do
        service.log_feedback(**valid_params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including(
            'metadata' => hash_including(
              'conversation_id' => 789,
              'account_id' => account_id
            )
          ))
      end

      it 'strips whitespace from prompt and response' do
        params = valid_params.merge(
          prompt: '  Customer question  ',
          response: '  Agent response  '
        )

        service.log_feedback(**params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including(
            'prompt' => 'Customer question',
            'response' => 'Agent response'
          ))
      end

      it 'strips whitespace from feedback text' do
        params = valid_params.merge(feedback: '  Great suggestion!  ')

        service.log_feedback(**params)

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including('feedback' => 'Great suggestion!'))
      end

      it 'handles nil feedback gracefully' do
        params = valid_params.except(:feedback)

        expect { service.log_feedback(**params) }.not_to raise_error

        expect(WebMock).to have_requested(:post, %r{database/rlhf})
          .with(body: hash_including('feedback' => nil))
      end

      it 'handles empty metadata gracefully' do
        params = valid_params.merge(metadata: {})

        expect { service.log_feedback(**params) }.not_to raise_error
      end

      described_class::VALID_SUGGESTION_TYPES.each do |suggestion_type|
        it "accepts valid suggestion_type: #{suggestion_type}" do
          params = valid_params.merge(suggestion_type: suggestion_type)

          expect { service.log_feedback(**params) }.not_to raise_error

          expect(WebMock).to have_requested(:post, %r{database/rlhf})
            .with(body: hash_including('interaction_type' => suggestion_type))
        end
      end

      (described_class::MIN_RATING..described_class::MAX_RATING).each do |rating|
        it "accepts valid rating: #{rating}" do
          params = valid_params.merge(rating: rating)

          expect { service.log_feedback(**params) }.not_to raise_error

          expect(WebMock).to have_requested(:post, %r{database/rlhf})
            .with(body: hash_including('rating' => rating))
        end
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError for invalid suggestion_type' do
        params = valid_params.merge(suggestion_type: 'invalid_type')

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Invalid suggestion_type: invalid_type/
        )
      end

      it 'raises ArgumentError for rating below minimum' do
        params = valid_params.merge(rating: 0)

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Invalid rating: 0/
        )
      end

      it 'raises ArgumentError for rating above maximum' do
        params = valid_params.merge(rating: 6)

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Invalid rating: 6/
        )
      end

      it 'raises ArgumentError for non-integer rating' do
        params = valid_params.merge(rating: 'five')

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Invalid rating/
        )
      end

      it 'raises ArgumentError for blank prompt' do
        params = valid_params.merge(prompt: '')

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Prompt cannot be blank/
        )
      end

      it 'raises ArgumentError for nil prompt' do
        params = valid_params.merge(prompt: nil)

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Prompt cannot be blank/
        )
      end

      it 'raises ArgumentError for blank response' do
        params = valid_params.merge(response: '')

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Response cannot be blank/
        )
      end

      it 'raises ArgumentError for nil response' do
        params = valid_params.merge(response: nil)

        expect { service.log_feedback(**params) }.to raise_error(
          ArgumentError,
          /Response cannot be blank/
        )
      end
    end

    context 'when API request fails' do
      it 'raises error for 401 Unauthorized' do
        stub_request(:post, %r{database/rlhf})
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json)

        expect { service.log_feedback(**valid_params) }.to raise_error(StandardError)
      end

      it 'raises error for 422 Unprocessable Entity' do
        stub_request(:post, %r{database/rlhf})
          .to_return(status: 422, body: { error: 'Invalid data' }.to_json)

        expect { service.log_feedback(**valid_params) }.to raise_error(StandardError)
      end

      it 'raises error for 500 Internal Server Error' do
        stub_request(:post, %r{database/rlhf})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)

        expect { service.log_feedback(**valid_params) }.to raise_error(StandardError)
      end

      it 'logs the error when API fails' do
        stub_request(:post, %r{database/rlhf})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)

        allow(Rails.logger).to receive(:error)

        begin
          service.log_feedback(**valid_params)
        rescue StandardError
          nil
        end

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/RLHF feedback logging failed/)
        )
      end

      it 'handles network timeout gracefully' do
        stub_request(:post, %r{database/rlhf})
          .to_timeout

        expect { service.log_feedback(**valid_params) }.to raise_error(StandardError)
      end

      it 'handles malformed JSON response' do
        stub_request(:post, %r{database/rlhf})
          .to_return(status: 200, body: 'invalid json')

        allow(Rails.logger).to receive(:error)

        result = service.log_feedback(**valid_params)

        expect(result).to have_key(:success)
        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Failed to parse RLHF API response/)
        )
      end
    end
  end

  describe '#get_stats' do
    let(:stats_response) do
      {
        'total_feedback' => 150,
        'avg_rating' => 4.2,
        'feedback_by_type' => {
          'canned_response_suggestion' => 80,
          'semantic_search' => 70
        },
        'recent_feedback' => [
          { 'id' => 'abc123', 'rating' => 5 },
          { 'id' => 'def456', 'rating' => 4 }
        ],
        'time_period' => '30_days'
      }
    end

    context 'with successful API response' do
      before do
        stub_request(:get, %r{#{base_url}/test-project-id/database/rlhf/stats})
          .with(query: hash_including('account_id' => account_id.to_s))
          .to_return(
            status: 200,
            body: stats_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'retrieves RLHF statistics' do
        result = service.get_stats

        expect(result).to be_a(Hash)
        expect(result['total_feedback']).to eq(150)
        expect(result['avg_rating']).to eq(4.2)
      end

      it 'includes feedback breakdown by type' do
        result = service.get_stats

        expect(result['feedback_by_type']).to be_a(Hash)
        expect(result['feedback_by_type']['canned_response_suggestion']).to eq(80)
        expect(result['feedback_by_type']['semantic_search']).to eq(70)
      end

      it 'includes recent feedback items' do
        result = service.get_stats

        expect(result['recent_feedback']).to be_an(Array)
        expect(result['recent_feedback'].size).to eq(2)
      end

      it 'sends correct request headers' do
        service.get_stats

        expect(WebMock).to have_requested(:get, %r{database/rlhf/stats})
          .with(
            headers: {
              'Authorization' => 'Bearer test-api-key',
              'X-Project-ID' => 'test-project-id'
            }
          )
      end

      it 'includes account_id in query parameters' do
        service.get_stats

        expect(WebMock).to have_requested(:get, %r{database/rlhf/stats})
          .with(query: hash_including('account_id' => account_id.to_s))
      end
    end

    context 'when API request fails' do
      it 'raises error for 404 Not Found' do
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(status: 404, body: { error: 'Not found' }.to_json)

        expect { service.get_stats }.to raise_error(StandardError)
      end

      it 'raises error for 500 Internal Server Error' do
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)

        expect { service.get_stats }.to raise_error(StandardError)
      end

      it 'logs the error when stats retrieval fails' do
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)

        allow(Rails.logger).to receive(:error)

        begin
          service.get_stats
        rescue StandardError
          nil
        end

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/RLHF stats retrieval failed/)
        )
      end

      it 'handles empty stats response' do
        stub_request(:get, %r{database/rlhf/stats})
          .to_return(
            status: 200,
            body: { 'total_feedback' => 0, 'avg_rating' => 0 }.to_json
          )

        result = service.get_stats

        expect(result['total_feedback']).to eq(0)
        expect(result['avg_rating']).to eq(0)
      end
    end
  end

  describe '.thumbs_to_rating' do
    it 'converts :up to maximum rating' do
      expect(described_class.thumbs_to_rating(:up)).to eq(5)
    end

    it 'converts :down to minimum rating' do
      expect(described_class.thumbs_to_rating(:down)).to eq(1)
    end

    it 'converts string "up" to maximum rating' do
      expect(described_class.thumbs_to_rating('up')).to eq(5)
    end

    it 'converts string "down" to minimum rating' do
      expect(described_class.thumbs_to_rating('down')).to eq(1)
    end

    it 'converts "thumbs_up" to maximum rating' do
      expect(described_class.thumbs_to_rating('thumbs_up')).to eq(5)
    end

    it 'converts "thumbs_down" to minimum rating' do
      expect(described_class.thumbs_to_rating('thumbs_down')).to eq(1)
    end

    it 'raises ArgumentError for invalid thumbs value' do
      expect { described_class.thumbs_to_rating('invalid') }.to raise_error(
        ArgumentError,
        /Invalid thumbs value: invalid/
      )
    end

    it 'raises ArgumentError for nil thumbs value' do
      expect { described_class.thumbs_to_rating(nil) }.to raise_error(
        ArgumentError,
        /Invalid thumbs value/
      )
    end

    it 'raises ArgumentError for numeric thumbs value' do
      expect { described_class.thumbs_to_rating(1) }.to raise_error(
        ArgumentError,
        /Invalid thumbs value/
      )
    end
  end

  describe 'constants' do
    it 'defines valid suggestion types' do
      expect(described_class::VALID_SUGGESTION_TYPES).to be_an(Array)
      expect(described_class::VALID_SUGGESTION_TYPES).to include(
        'canned_response_suggestion',
        'semantic_search',
        'ai_assistant',
        'smart_reply'
      )
    end

    it 'defines minimum rating' do
      expect(described_class::MIN_RATING).to eq(1)
    end

    it 'defines maximum rating' do
      expect(described_class::MAX_RATING).to eq(5)
    end

    it 'has frozen VALID_SUGGESTION_TYPES array' do
      expect(described_class::VALID_SUGGESTION_TYPES).to be_frozen
    end
  end

  describe 'edge cases' do
    before do
      stub_request(:post, %r{database/rlhf})
        .to_return(
          status: 200,
          body: { 'id' => 'test-id' }.to_json
        )
    end

    it 'handles very long prompt text' do
      long_prompt = 'a' * 10_000
      params = {
        suggestion_type: 'semantic_search',
        prompt: long_prompt,
        response: 'Short response',
        rating: 3
      }

      expect { service.log_feedback(**params) }.not_to raise_error

      expect(WebMock).to have_requested(:post, %r{database/rlhf})
        .with(body: hash_including('prompt' => long_prompt))
    end

    it 'handles very long response text' do
      long_response = 'b' * 10_000
      params = {
        suggestion_type: 'semantic_search',
        prompt: 'Short prompt',
        response: long_response,
        rating: 3
      }

      expect { service.log_feedback(**params) }.not_to raise_error

      expect(WebMock).to have_requested(:post, %r{database/rlhf})
        .with(body: hash_including('response' => long_response))
    end

    it 'handles special characters in prompt' do
      special_prompt = "Customer: What's the policy? 🤔 <script>alert('xss')</script>"
      params = {
        suggestion_type: 'semantic_search',
        prompt: special_prompt,
        response: 'Response',
        rating: 3
      }

      expect { service.log_feedback(**params) }.not_to raise_error

      expect(WebMock).to have_requested(:post, %r{database/rlhf})
        .with(body: hash_including('prompt' => special_prompt))
    end

    it 'handles unicode characters in feedback' do
      unicode_feedback = 'Great! 👍 Very helpful 中文 العربية'
      params = {
        suggestion_type: 'semantic_search',
        prompt: 'Test',
        response: 'Test response',
        rating: 5,
        feedback: unicode_feedback
      }

      expect { service.log_feedback(**params) }.not_to raise_error
    end

    it 'handles deeply nested metadata' do
      nested_metadata = {
        conversation: {
          id: 123,
          messages: {
            count: 5,
            last: { id: 456, content: 'text' }
          }
        }
      }

      params = {
        suggestion_type: 'semantic_search',
        prompt: 'Test',
        response: 'Test response',
        rating: 4,
        metadata: nested_metadata
      }

      expect { service.log_feedback(**params) }.not_to raise_error
    end
  end
end
