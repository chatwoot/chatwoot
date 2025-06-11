require 'rails_helper'

RSpec.describe Linear::ActivityMessageService, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#perform' do
    context 'when action_type is issue_created' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: { id: 'ENG-123' }
        )
      end

      it 'enqueues an activity message job' do
        expect do
          service.perform
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, {
                  account_id: conversation.account_id,
                  inbox_id: conversation.inbox_id,
                  message_type: :activity,
                  content: 'New Linear issue ENG-123 has been created'
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: { title: 'Some issue' }
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end

      it 'does not enqueue job when issue_data is empty' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: {}
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end

      it 'does not enqueue job when conversation is nil' do
        service = described_class.new(
          conversation: nil,
          action_type: :issue_created,
          issue_data: { id: 'ENG-123' }
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end
    end

    context 'when action_type is issue_linked' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          action_type: :issue_linked,
          issue_data: { id: 'ENG-456' }
        )
      end

      it 'enqueues an activity message job' do
        expect do
          service.perform
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, {
                  account_id: conversation.account_id,
                  inbox_id: conversation.inbox_id,
                  message_type: :activity,
                  content: 'Linear issue ENG-456 is now linked'
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_linked,
          issue_data: { title: 'Some issue' }
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end
    end

    context 'when action_type is issue_unlinked' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          action_type: :issue_unlinked,
          issue_data: { id: 'ENG-789' }
        )
      end

      it 'enqueues an activity message job' do
        expect do
          service.perform
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, {
                  account_id: conversation.account_id,
                  inbox_id: conversation.inbox_id,
                  message_type: :activity,
                  content: 'Linear issue ENG-789 has been unlinked'
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_unlinked,
          issue_data: { title: 'Some issue' }
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end
    end

    context 'when action_type is unknown' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          action_type: :unknown_action,
          issue_data: { id: 'ENG-999' }
        )
      end

      it 'does not enqueue job for unknown action types' do
        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end
    end
  end
end