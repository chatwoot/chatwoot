# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::IndexConversationJob, type: :job do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:service) { instance_double(Zerodb::SemanticSearchService) }

  before do
    # Set required environment variables
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project'
    ENV['OPENAI_API_KEY'] = 'test-openai-key'

    # Mock the service
    allow(Zerodb::SemanticSearchService).to receive(:new).and_return(service)
    allow(service).to receive(:index_conversation).and_return({ 'status' => 'success' })
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
    ENV.delete('OPENAI_API_KEY')
  end

  describe '#perform' do
    context 'with valid conversation' do
      before do
        create(:message, conversation: conversation, content: 'Test message', message_type: 'incoming')
      end

      it 'indexes the conversation using SemanticSearchService' do
        job.perform(conversation.id)

        expect(service).to have_received(:index_conversation).with(conversation)
      end

      it 'returns the service result' do
        result = job.perform(conversation.id)

        expect(result).to eq({ 'status' => 'success' })
      end

      it 'logs successful indexing' do
        allow(Rails.logger).to receive(:info)

        job.perform(conversation.id)

        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(/Successfully indexed conversation #{conversation.id}/)
        )
      end
    end

    context 'with conversation without messages' do
      it 'skips indexing and logs skip message' do
        allow(Rails.logger).to receive(:info)

        job.perform(conversation.id)

        expect(service).not_to have_received(:index_conversation)
        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(/Skipping conversation #{conversation.id} - no messages/)
        )
      end
    end

    context 'with only activity messages' do
      before do
        create(:message, conversation: conversation, content: 'Activity', message_type: 'activity')
      end

      it 'skips indexing for activity-only conversations' do
        job.perform(conversation.id)

        expect(service).not_to have_received(:index_conversation)
      end
    end

    context 'when conversation does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { job.perform(999_999) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(999_999) }.to raise_error(ActiveRecord::RecordNotFound)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Conversation 999999 not found/)
        )
      end
    end

    context 'when service raises NetworkError' do
      before do
        create(:message, conversation: conversation, content: 'Test', message_type: 'incoming')
        allow(service).to receive(:index_conversation).and_raise(
          Zerodb::BaseService::NetworkError.new('Network timeout')
        )
      end

      it 'retries the job' do
        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::NetworkError)
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::NetworkError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Failed to index conversation #{conversation.id}/)
        )
      end
    end

    context 'when service raises RateLimitError' do
      before do
        create(:message, conversation: conversation, content: 'Test', message_type: 'incoming')
        allow(service).to receive(:index_conversation).and_raise(
          Zerodb::BaseService::RateLimitError.new('Rate limit exceeded')
        )
      end

      it 'retries the job with delay' do
        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::RateLimitError)
      end
    end

    context 'when service raises AuthenticationError' do
      before do
        create(:message, conversation: conversation, content: 'Test', message_type: 'incoming')
        allow(service).to receive(:index_conversation).and_raise(
          Zerodb::BaseService::AuthenticationError.new('Invalid API key')
        )
      end

      it 'discards the job without retry' do
        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::AuthenticationError)
      end

      it 'logs authentication error' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::AuthenticationError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Authentication failed for conversation #{conversation.id}/)
        )
      end
    end

    context 'when service raises ValidationError' do
      before do
        create(:message, conversation: conversation, content: 'Test', message_type: 'incoming')
        allow(service).to receive(:index_conversation).and_raise(
          Zerodb::BaseService::ValidationError.new('Invalid data')
        )
      end

      it 'discards the job without retry' do
        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::ValidationError)
      end

      it 'logs validation error' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(conversation.id) }.to raise_error(Zerodb::BaseService::ValidationError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Validation failed for conversation #{conversation.id}/)
        )
      end
    end

    context 'when an unexpected error occurs' do
      before do
        create(:message, conversation: conversation, content: 'Test', message_type: 'incoming')
        allow(service).to receive(:index_conversation).and_raise(StandardError.new('Unexpected error'))
      end

      it 'raises the error' do
        expect { job.perform(conversation.id) }.to raise_error(StandardError, 'Unexpected error')
      end

      it 'logs error with backtrace' do
        allow(Rails.logger).to receive(:error)

        expect { job.perform(conversation.id) }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Failed to index conversation #{conversation.id}: Unexpected error/)
        )
        expect(Rails.logger).to have_received(:error).with(a_kind_of(String))
      end
    end
  end

  describe 'job configuration' do
    it 'uses default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'retries on NetworkError with exponential backoff' do
      retry_config = described_class.retry_on_block_for(Zerodb::BaseService::NetworkError)
      expect(retry_config).not_to be_nil
    end

    it 'retries on RateLimitError with delay' do
      retry_config = described_class.retry_on_block_for(Zerodb::BaseService::RateLimitError)
      expect(retry_config).not_to be_nil
    end

    it 'discards on AuthenticationError' do
      discard_config = described_class.discard_on_block_for(Zerodb::BaseService::AuthenticationError)
      expect(discard_config).not_to be_nil
    end

    it 'discards on ValidationError' do
      discard_config = described_class.discard_on_block_for(Zerodb::BaseService::ValidationError)
      expect(discard_config).not_to be_nil
    end

    it 'discards on RecordNotFound' do
      discard_config = described_class.discard_on_block_for(ActiveRecord::RecordNotFound)
      expect(discard_config).not_to be_nil
    end
  end

  describe 'integration with Message model' do
    context 'when a message is created' do
      it 'enqueues IndexConversationJob' do
        expect do
          create(:message, conversation: conversation, content: 'New message', message_type: 'incoming')
        end.to have_enqueued_job(described_class).with(conversation.id)
      end

      it 'does not enqueue for activity messages' do
        expect do
          create(:message, conversation: conversation, content: 'Activity', message_type: 'activity')
        end.not_to have_enqueued_job(described_class)
      end

      it 'does not enqueue for messages without content' do
        expect do
          create(:message, conversation: conversation, content: '', message_type: 'incoming')
        end.not_to have_enqueued_job(described_class)
      end
    end
  end

  describe 'performance' do
    before do
      create(:message, conversation: conversation, content: 'Test message', message_type: 'incoming')
    end

    it 'completes job execution quickly' do
      start_time = Time.current

      job.perform(conversation.id)

      duration = Time.current - start_time
      expect(duration).to be < 5.0 # Should complete in less than 5 seconds
    end
  end
end
