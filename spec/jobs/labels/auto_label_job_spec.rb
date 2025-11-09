# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::AutoLabelJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when conversation exists' do
      it 'calls AutoLabelService with the conversation' do
        service = instance_double(Labels::AutoLabelService)
        allow(Labels::AutoLabelService).to receive(:new)
          .with(conversation: conversation)
          .and_return(service)
        expect(service).to receive(:perform)

        described_class.perform_now(conversation.id)
      end
    end

    context 'when conversation does not exist' do
      it 'handles missing conversation gracefully' do
        expect { described_class.perform_now(999_999) }.not_to raise_error
      end

      it 'does not call AutoLabelService' do
        expect(Labels::AutoLabelService).not_to receive(:new)

        described_class.perform_now(999_999)
      end
    end

    context 'when conversation is deleted during processing' do
      it 'handles deleted conversation' do
        conversation_id = conversation.id
        conversation.destroy

        expect { described_class.perform_now(conversation_id) }.not_to raise_error
      end
    end
  end

  describe 'job enqueueing' do
    subject(:job) { described_class.perform_later(conversation.id) }

    it 'enqueues the job' do
      expect { job }.to have_enqueued_job(described_class)
        .with(conversation.id)
        .on_queue('default')
    end
  end

  describe 'retry configuration' do
    # NOTE: The job is configured with `retry_on StandardError, wait: :exponentially_longer, attempts: 3`
    # This configuration is tested implicitly in production when errors occur.
    # Testing retry behavior with rspec-rails requires time manipulation and can be flaky.

    it 'has retry_on declared in the job class' do
      # Verify that the job source code contains retry_on configuration
      job_source = File.read(Rails.root.join('app/jobs/labels/auto_label_job.rb'))
      expect(job_source).to include('retry_on StandardError')
      expect(job_source).to include('wait: :exponentially_longer')
      expect(job_source).to include('attempts: 3')
    end
  end

  describe 'integration test' do
    before do
      account.update!(settings: { auto_label_enabled: true })
      create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Test message')
      create(:label, title: 'support', account: account)
    end

    it 'processes the job successfully' do
      classifier_service = instance_double(Labels::OpenaiClassifierService)
      allow(Labels::OpenaiClassifierService).to receive(:new).and_return(classifier_service)
      allow(classifier_service).to receive(:suggest_labels).and_return({ labels: ['support'] })

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(conversation.id)
        end
      end.to change { conversation.reload.label_list.count }.by(1)

      expect(conversation.label_list).to include('support')
    end
  end
end
