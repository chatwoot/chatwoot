require 'rails_helper'

RSpec.describe Linear::ActivityMessageService, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when action_type is issue_created' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: { id: 'ENG-123' },
          user: user
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
                  content: "Linear issue ENG-123 was created by #{user.name}"
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: { title: 'Some issue' },
          user: user
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end

      it 'does not enqueue job when issue_data is empty' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: {},
          user: user
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end

      it 'does not enqueue job when conversation is nil' do
        service = described_class.new(
          conversation: nil,
          action_type: :issue_created,
          issue_data: { id: 'ENG-123' },
          user: user
        )

        expect do
          service.perform
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
      end

      it 'does not enqueue job when user is nil' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_created,
          issue_data: { id: 'ENG-123' },
          user: nil
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
          issue_data: { id: 'ENG-456' },
          user: user
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
                  content: "Linear issue ENG-456 was linked by #{user.name}"
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_linked,
          issue_data: { title: 'Some issue' },
          user: user
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
          issue_data: { id: 'ENG-789' },
          user: user
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
                  content: "Linear issue ENG-789 was unlinked by #{user.name}"
                })
      end

      it 'does not enqueue job when issue data lacks id' do
        service = described_class.new(
          conversation: conversation,
          action_type: :issue_unlinked,
          issue_data: { title: 'Some issue' },
          user: user
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
          issue_data: { id: 'ENG-999' },
          user: user
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
