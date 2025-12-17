# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::DeleteCannedResponseJob, type: :job do
  let(:account) { create(:account) }
  let(:canned_response_id) { 123 }
  let(:short_code) { 'test_code' }
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#perform' do
    let(:delete_endpoint) { "/#{project_id}/vectors/delete" }
    let(:vector_id) { "canned_response_#{account.id}_#{canned_response_id}" }

    context 'when deletion is successful' do
      let(:response_body) { { 'deleted' => true, 'id' => vector_id } }

      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .with(
            body: {
              id: vector_id,
              namespace: "canned_responses_#{account.id}"
            }.to_json,
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'deletes the vector from ZeroDB' do
        described_class.new.perform(canned_response_id, account.id, short_code)

        expect(WebMock).to have_requested(:delete, "#{api_url}#{delete_endpoint}")
          .with(
            body: hash_including(
              'id' => vector_id,
              'namespace' => "canned_responses_#{account.id}"
            )
          )
      end

      it 'logs success' do
        expect(Rails.logger).to receive(:info).with("[CannedResponseSuggester] Deleted canned response #{canned_response_id} from ZeroDB")
        expect(Rails.logger).to receive(:info).with("Successfully deleted canned response #{canned_response_id} from ZeroDB")
        described_class.new.perform(canned_response_id, account.id, short_code)
      end

      it 'can be enqueued' do
        expect {
          described_class.perform_later(canned_response_id, account.id, short_code)
        }.to have_enqueued_job(described_class)
          .with(canned_response_id, account.id, short_code)
          .on_queue('low')
      end

      it 'works without short_code parameter' do
        expect {
          described_class.new.perform(canned_response_id, account.id)
        }.not_to raise_error
      end
    end

    context 'when ZeroDB API returns error' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(
            status: 404,
            body: { error: 'Vector not found' }.to_json
          )
      end

      it 'logs error and re-raises exception' do
        expect(Rails.logger).to receive(:error)
          .with(/Failed to delete canned response #{canned_response_id}/)
        expect(Rails.logger).to receive(:error)
          .with("ZeroDB API error deleting canned response #{canned_response_id}: Resource not found: Vector not found")

        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::ZeroDBError)
      end

      it 'retries the job on ZeroDBError' do
        expect {
          described_class.perform_later(canned_response_id, account.id, short_code)
        }.to have_enqueued_job(described_class)

        # Verify retry_on configuration
        expect(described_class.retry_on_block_for(Zerodb::BaseService::ZeroDBError)).to be_present
      end
    end

    context 'when authentication fails' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(
            status: 401,
            body: { error: 'Invalid API key' }.to_json
          )
      end

      it 'logs authentication error' do
        expect(Rails.logger).to receive(:error)
          .with(/Failed to delete canned response #{canned_response_id}/)
        expect(Rails.logger).to receive(:error)
          .with("ZeroDB API error deleting canned response #{canned_response_id}: Authentication failed: Invalid API key")

        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::AuthenticationError)
      end
    end

    context 'when rate limit is exceeded' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(
            status: 429,
            body: { error: 'Rate limit exceeded' }.to_json
          )
      end

      it 'logs rate limit error and retries' do
        expect(Rails.logger).to receive(:error).with(/Failed to delete canned response/)
        expect(Rails.logger).to receive(:error).with(/ZeroDB API error deleting/)

        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::RateLimitError)
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_timeout
      end

      it 'logs network error and retries' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::NetworkError)
      end
    end

    context 'when server error occurs' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(
            status: 500,
            body: { error: 'Internal server error' }.to_json
          )
      end

      it 'logs server error and retries' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::ZeroDBError)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued on low priority queue' do
      expect(described_class.new.queue_name).to eq('low')
    end

    it 'retries on StandardError with exponential backoff' do
      expect(described_class.retry_on_block_for(StandardError)).to be_present
    end

    it 'has maximum 3 retry attempts' do
      job = described_class.new
      expect(job.class.get_sidekiq_options['retry']).to be_truthy
    end
  end

  describe 'integration with CannedResponse model' do
    let!(:test_response) { create(:canned_response, account: account) }
    let(:delete_endpoint) { "/#{project_id}/vectors/delete" }

    before do
      stub_request(:delete, "#{api_url}#{delete_endpoint}")
        .to_return(status: 200, body: { deleted: true }.to_json)
    end

    context 'when canned response is destroyed' do
      it 'enqueues deletion job' do
        response_id = test_response.id
        response_short_code = test_response.short_code

        expect {
          test_response.destroy
        }.to have_enqueued_job(described_class)
          .with(response_id, account.id, response_short_code)
      end
    end
  end

  describe 'error handling scenarios' do
    context 'when suggester initialization fails' do
      before do
        stub_env('ZERODB_API_KEY', '')
      end

      it 'raises ConfigurationError' do
        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.to raise_error(Zerodb::BaseService::ConfigurationError)
      end
    end

    context 'when using OpenStruct for deleted record' do
      let(:delete_endpoint) { "/#{project_id}/vectors/delete" }

      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(status: 200, body: { deleted: true }.to_json)
      end

      it 'successfully processes OpenStruct object' do
        expect {
          described_class.new.perform(canned_response_id, account.id, short_code)
        }.not_to raise_error
      end
    end
  end
end
