require 'rails_helper'

RSpec.describe Zerodb::BaseService, type: :service do
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#initialize' do
    context 'when credentials are valid' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'when API key is missing' do
      before { stub_env('ZERODB_API_KEY', nil) }

      it 'raises ConfigurationError' do
        expect { described_class.new }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          'ZERODB_API_KEY environment variable is not set'
        )
      end
    end

    context 'when project ID is missing' do
      before { stub_env('ZERODB_PROJECT_ID', nil) }

      it 'raises ConfigurationError' do
        expect { described_class.new }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          'ZERODB_PROJECT_ID environment variable is not set'
        )
      end
    end

    context 'when both credentials are missing' do
      before do
        stub_env('ZERODB_API_KEY', nil)
        stub_env('ZERODB_PROJECT_ID', nil)
      end

      it 'raises ConfigurationError for API key first' do
        expect { described_class.new }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          'ZERODB_API_KEY environment variable is not set'
        )
      end
    end
  end

  describe 'API request handling' do
    let(:service) { described_class.new }
    let(:endpoint) { '/test-endpoint' }
    let(:full_path) { "/#{project_id}#{endpoint}" }

    describe 'successful requests' do
      context 'when API returns 200 OK' do
        let(:response_body) { { 'status' => 'success', 'data' => { 'id' => 123 } } }

        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .with(headers: {
                    'X-API-Key' => api_key,
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                  })
            .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns parsed response' do
          result = service.send(:make_request, :get, full_path)
          expect(result).to eq(response_body)
        end
      end

      context 'when API returns 201 Created' do
        let(:response_body) { { 'id' => 456, 'created' => true } }

        before do
          stub_request(:post, "#{api_url}#{full_path}")
            .to_return(status: 201, body: response_body.to_json)
        end

        it 'returns parsed response' do
          result = service.send(:make_request, :post, full_path, body: {}.to_json)
          expect(result).to eq(response_body)
        end
      end
    end

    describe 'authentication errors' do
      context 'when API returns 401 Unauthorized' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 401,
              body: { error: 'Invalid API key' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises AuthenticationError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::AuthenticationError,
            /Authentication failed: Invalid API key/
          )
        end
      end

      context 'when API returns 403 Forbidden' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 403,
              body: { error: 'Access denied' }.to_json
            )
        end

        it 'raises AuthenticationError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::AuthenticationError,
            /Authentication failed: Access denied/
          )
        end
      end
    end

    describe 'rate limiting' do
      context 'when API returns 429 Too Many Requests' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 429,
              body: { error: 'Rate limit exceeded. Please try again in 60 seconds' }.to_json
            )
        end

        it 'raises RateLimitError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::RateLimitError,
            /Rate limit exceeded/
          )
        end
      end
    end

    describe 'validation errors' do
      context 'when API returns 400 Bad Request' do
        before do
          stub_request(:post, "#{api_url}#{full_path}")
            .to_return(
              status: 400,
              body: { error: 'Invalid request format' }.to_json
            )
        end

        it 'raises ValidationError' do
          expect { service.send(:make_request, :post, full_path, body: {}.to_json) }.to raise_error(
            Zerodb::BaseService::ValidationError,
            /Validation error: Invalid request format/
          )
        end
      end

      context 'when API returns 422 Unprocessable Entity' do
        before do
          stub_request(:post, "#{api_url}#{full_path}")
            .to_return(
              status: 422,
              body: { error: 'Vector dimension mismatch' }.to_json
            )
        end

        it 'raises ValidationError' do
          expect { service.send(:make_request, :post, full_path, body: {}.to_json) }.to raise_error(
            Zerodb::BaseService::ValidationError,
            /Vector dimension mismatch/
          )
        end
      end
    end

    describe 'resource not found' do
      context 'when API returns 404 Not Found' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 404,
              body: { error: 'Vector not found' }.to_json
            )
        end

        it 'raises ZeroDBError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::ZeroDBError,
            /Resource not found: Vector not found/
          )
        end
      end
    end

    describe 'server errors' do
      context 'when API returns 500 Internal Server Error' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 500,
              body: { error: 'Internal server error' }.to_json
            )
        end

        it 'raises ZeroDBError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::ZeroDBError,
            /ZeroDB server error: Internal server error/
          )
        end
      end

      context 'when API returns 503 Service Unavailable' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 503,
              body: { error: 'Service temporarily unavailable' }.to_json
            )
        end

        it 'raises ZeroDBError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::ZeroDBError,
            /Service temporarily unavailable/
          )
        end
      end
    end

    describe 'network errors and retry logic' do
      context 'when network timeout occurs' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_timeout
        end

        it 'retries and raises NetworkError after max retries' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::NetworkError,
            /Failed to connect to ZeroDB API after 3 retries/
          )
        end

        it 'attempts request exactly MAX_RETRIES + 1 times' do
          begin
            service.send(:make_request, :get, full_path)
          rescue Zerodb::BaseService::NetworkError
            # Expected
          end

          expect(WebMock).to have_requested(:get, "#{api_url}#{full_path}").times(4) # Initial + 3 retries
        end
      end

      context 'when connection is refused' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_raise(Errno::ECONNREFUSED)
        end

        it 'retries and raises NetworkError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::NetworkError,
            /Failed to connect to ZeroDB API/
          )
        end
      end

      context 'when request succeeds after retry' do
        let(:response_body) { { 'status' => 'success' } }

        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_timeout.then
            .to_return(status: 200, body: response_body.to_json)
        end

        it 'returns successful response' do
          result = service.send(:make_request, :get, full_path)
          expect(result).to eq(response_body)
        end
      end
    end

    describe 'invalid JSON response' do
      context 'when API returns invalid JSON' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 200,
              body: 'invalid json {{{',
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises ZeroDBError' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::ZeroDBError,
            /Invalid JSON response from API/
          )
        end
      end
    end

    describe 'unexpected status codes' do
      context 'when API returns unexpected status code' do
        before do
          stub_request(:get, "#{api_url}#{full_path}")
            .to_return(
              status: 418,
              body: { error: "I'm a teapot" }.to_json
            )
        end

        it 'raises ZeroDBError with status code' do
          expect { service.send(:make_request, :get, full_path) }.to raise_error(
            Zerodb::BaseService::ZeroDBError,
            /Unexpected error \(418\)/
          )
        end
      end
    end
  end

  describe 'error message parsing' do
    let(:service) { described_class.new }

    it 'extracts error from "error" field' do
      response = double(body: { error: 'Custom error' }.to_json, message: 'Default')
      message = service.send(:parse_error_message, response)
      expect(message).to eq('Custom error')
    end

    it 'extracts error from "message" field' do
      response = double(body: { message: 'Error message' }.to_json, message: 'Default')
      message = service.send(:parse_error_message, response)
      expect(message).to eq('Error message')
    end

    it 'extracts error from "detail" field' do
      response = double(body: { detail: 'Detailed error' }.to_json, message: 'Default')
      message = service.send(:parse_error_message, response)
      expect(message).to eq('Detailed error')
    end

    it 'falls back to response message when body is empty' do
      response = double(body: nil, message: 'Response message')
      message = service.send(:parse_error_message, response)
      expect(message).to eq('Response message')
    end

    it 'handles invalid JSON in error response' do
      response = double(body: 'not json', message: 'Fallback message')
      message = service.send(:parse_error_message, response)
      expect(message).to eq('Fallback message')
    end
  end
end
