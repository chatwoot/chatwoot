# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoAssignConversationJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when conversation exists' do
      it 'calls Conversations::AutoAssignService with the conversation' do
        service = instance_double(Conversations::AutoAssignService)
        allow(Conversations::AutoAssignService).to receive(:new)
          .with(conversation)
          .and_return(service)
        expect(service).to receive(:perform)

        described_class.perform_now(conversation.id)
      end
    end

    context 'when conversation does not exist' do
      it 'handles missing conversation gracefully' do
        expect { described_class.perform_now(999_999) }.not_to raise_error
      end

      it 'does not call Conversations::AutoAssignService' do
        expect(Conversations::AutoAssignService).not_to receive(:new)

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
    it 'has retry_on declared in the job class' do
      job_source = File.read(Rails.root.join('app/jobs/auto_assign_conversation_job.rb'))
      expect(job_source).to include('retry_on StandardError')
      expect(job_source).to include('wait: :exponentially_longer')
      expect(job_source).to include('attempts: 3')
    end
  end

  describe 'integration test' do
    before do
      account.update!(settings: { auto_label_enabled: true, auto_team_enabled: true })
      create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Test message')
    end

    it 'processes the job successfully' do
      label = create(:label, title: 'support', account: account)
      team = create(:team, name: 'Support Team', account: account)

      allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                   'label_id' => label.id,
                                                                   'team_id' => team.id
                                                                 })

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(conversation.id)
        end
      end.to change { conversation.reload.label_list.count }.by(1)
                                                            .and change { conversation.reload.team_id }.from(nil).to(team.id)

      expect(conversation.label_list).to include('support')
      expect(conversation.team).to eq(team)
    end
  end
end
