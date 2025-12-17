# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::IndexCannedResponseJob, type: :job do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:canned_response) { create(:canned_response, account: account, short_code: 'greeting', content: 'Hello! How can I help you today?') }
  let(:service) { instance_double(Zerodb::CannedResponseSuggester) }

  before do
    # Set required environment variables
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project'

    # Mock the service
    allow(Zerodb::CannedResponseSuggester).to receive(:new).with(account.id).and_return(service)
    allow(service).to receive(:index_response).and_return({ 'status' => 'success' })
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
  end

  describe '#perform' do
    context 'with valid canned response' do
      it 'indexes the canned response using CannedResponseSuggester' do
        job.perform(canned_response.id, account.id)

        expect(service).to have_received(:index_response).with(canned_response)
      end

      it 'logs successful indexing' do
        allow(Rails.logger).to receive(:info)

        job.perform(canned_response.id, account.id)

        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(/Successfully indexed canned response #{canned_response.id}/)
        )
      end
    end

    context 'when canned response does not exist' do
      it 'logs warning and returns early' do
        allow(Rails.logger).to receive(:warn)

        job.perform(999_999, account.id)

        expect(service).not_to have_received(:index_response)
        expect(Rails.logger).to have_received(:warn).with(
          a_string_matching(/CannedResponse 999999 not found/)
        )
      end

      it 'does not raise an error' do
        expect { job.perform(999_999, account.id) }.not_to raise_error
      end
    end

    context 'when account id does not match' do
      let(:other_account) { create(:account) }

      it 'does not index the canned response' do
        job.perform(canned_response.id, other_account.id)

        expect(service).not_to have_received(:index_response)
      end
    end

    context 'when service raises ZeroDBError' do
      before do
        allow(service).to receive(:index_response).and_raise(
          Zerodb::BaseService::ZeroDBError.new('API error')
        )
      end

      it 'raises the error for retry' do
        expect { job.perform(canned_response.id, account.id) }.to raise_error(Zerodb::BaseService::ZeroDBError)
      end

      it 'logs ZeroDB API error' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(canned_response.id, account.id) }.to raise_error(Zerodb::BaseService::ZeroDBError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/ZeroDB API error indexing canned response #{canned_response.id}/)
        )
      end
    end

    context 'when service raises AuthenticationError' do
      before do
        allow(service).to receive(:index_response).and_raise(
          Zerodb::BaseService::AuthenticationError.new('Invalid API key')
        )
      end

      it 'raises the error without retry' do
        expect { job.perform(canned_response.id, account.id) }.to raise_error(Zerodb::BaseService::AuthenticationError)
      end
    end

    context 'when service raises RateLimitError' do
      before do
        allow(service).to receive(:index_response).and_raise(
          Zerodb::BaseService::RateLimitError.new('Rate limit exceeded')
        )
      end

      it 'raises error for exponential backoff retry' do
        expect { job.perform(canned_response.id, account.id) }.to raise_error(Zerodb::BaseService::RateLimitError)
      end
    end

    context 'when service raises ValidationError' do
      before do
        allow(service).to receive(:index_response).and_raise(
          Zerodb::BaseService::ValidationError.new('Invalid data')
        )
      end

      it 'raises the error' do
        expect { job.perform(canned_response.id, account.id) }.to raise_error(Zerodb::BaseService::ValidationError)
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(service).to receive(:index_response).and_raise(StandardError.new('Unexpected error'))
      end

      it 'raises the error' do
        expect { job.perform(canned_response.id, account.id) }.to raise_error(StandardError, 'Unexpected error')
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(canned_response.id, account.id) }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Unexpected error indexing canned response #{canned_response.id}/)
        )
      end
    end
  end

  describe 'job configuration' do
    it 'uses low priority queue' do
      expect(described_class.new.queue_name).to eq('low')
    end

    it 'configures retry with exponential backoff' do
      # Verify retry configuration exists
      expect(described_class.retry_on_block_for(StandardError)).not_to be_nil
    end
  end

  describe 'integration with CannedResponse model' do
    context 'when a canned response is created' do
      it 'enqueues IndexCannedResponseJob' do
        expect do
          create(:canned_response, account: account, short_code: 'test', content: 'Test content')
        end.to have_enqueued_job(described_class)
      end
    end

    context 'when a canned response is updated' do
      it 'enqueues IndexCannedResponseJob for content change' do
        expect do
          canned_response.update(content: 'Updated content')
        end.to have_enqueued_job(described_class)
      end

      it 'enqueues IndexCannedResponseJob for short_code change' do
        expect do
          canned_response.update(short_code: 'updated_code')
        end.to have_enqueued_job(described_class)
      end

      it 'does not enqueue job for other attribute changes' do
        expect do
          canned_response.touch
        end.not_to have_enqueued_job(described_class)
      end
    end
  end

  describe 'performance' do
    it 'completes job execution quickly' do
      start_time = Time.current

      job.perform(canned_response.id, account.id)

      duration = Time.current - start_time
      expect(duration).to be < 3.0 # Should complete in less than 3 seconds
    end
  end
end
