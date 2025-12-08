require 'rails_helper'

RSpec.describe ChatQueue::Queue::EntryService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:service) { described_class.new(account: account) }

  let(:notification_service) { instance_double(ChatQueue::Queue::NotificationService) }

  before do
    allow(ChatQueue::Queue::NotificationService).to receive(:new)
      .with(conversation: conversation).and_return(notification_service)
    allow(notification_service).to receive(:send_queue_notification)
    allow(Queue::ProcessQueueJob).to receive(:perform_later)
  end

  describe '#prepare_for_queue!' do
    context 'when conversation has an assignee' do
      let(:agent) { create(:user, account: account) }

      before { conversation.update!(assignee: agent) }

      it 'clears the assignee' do
        service.prepare_for_queue!(conversation)
        expect(conversation.reload.assignee).to be_nil
      end

      it 'updates assignee_id to nil' do
        expect do
          service.prepare_for_queue!(conversation)
        end.to change { conversation.reload.assignee_id }.from(agent.id).to(nil)
      end
    end

    context 'when conversation has no assignee' do
      it 'does not change assignee' do
        expect do
          service.prepare_for_queue!(conversation)
        end.not_to(change { conversation.reload.assignee_id })
      end

      it 'keeps assignee as nil' do
        service.prepare_for_queue!(conversation)
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when creating queue entry' do
      it 'creates a queue entry with waiting status' do
        expect do
          service.prepare_for_queue!(conversation)
        end.to change(ConversationQueue, :count).by(1)

        queue_entry = ConversationQueue.find_by(conversation: conversation)

        expect(queue_entry).not_to be_nil
        expect(queue_entry.status).to eq('waiting')
        expect(queue_entry.account).to eq(account)
        expect(queue_entry.inbox_id).to eq(conversation.inbox_id)
        expect(queue_entry.conversation_id).to eq(conversation.id)
      end

      it 'sets queued_at timestamp' do
        freeze_time do
          service.prepare_for_queue!(conversation)
          queue_entry = ConversationQueue.find_by(conversation: conversation)

          expect(queue_entry.queued_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'associates queue entry with correct account and inbox' do
        service.prepare_for_queue!(conversation)
        queue_entry = ConversationQueue.last

        expect(queue_entry.account_id).to eq(account.id)
        expect(queue_entry.inbox_id).to eq(inbox.id)
      end
    end

    context 'when updating conversation status' do
      it 'updates conversation status to queued if not already queued' do
        expect do
          service.prepare_for_queue!(conversation)
        end.to change { conversation.reload.status }.from('open').to('queued')
      end

      it 'does not change conversation status if already queued' do
        conversation.update!(status: :queued)

        expect do
          service.prepare_for_queue!(conversation)
        end.not_to(change { conversation.reload.status })

        expect(conversation.reload.status).to eq('queued')
      end

      it 'creates queue entry even when conversation already queued' do
        conversation.update!(status: :queued)

        expect do
          service.prepare_for_queue!(conversation)
        end.to change(ConversationQueue, :count).by(1)
      end
    end

    context 'when sending notifications and enqueuing jobs' do
      it 'sends queue notification' do
        service.prepare_for_queue!(conversation)
        expect(notification_service).to have_received(:send_queue_notification).once
      end

      it 'enqueues process queue job with correct parameters' do
        service.prepare_for_queue!(conversation)
        expect(Queue::ProcessQueueJob).to have_received(:perform_later).with(account.id, inbox.id)
      end
    end

    context 'with multiple conversations' do
      let(:conversation2) { create(:conversation, account: account, inbox: inbox, status: :open) }
      let(:agent) { create(:user, account: account) }
      let(:notification_service2) { instance_double(ChatQueue::Queue::NotificationService) }

      before do
        conversation.update!(assignee: agent)

        allow(ChatQueue::Queue::NotificationService).to receive(:new)
          .with(conversation: conversation2).and_return(notification_service2)
        allow(notification_service2).to receive(:send_queue_notification)
      end

      it 'creates separate queue entries' do
        service.prepare_for_queue!(conversation)
        service.prepare_for_queue!(conversation2)

        expect(ConversationQueue.where(conversation: conversation).count).to eq(1)
        expect(ConversationQueue.where(conversation: conversation2).count).to eq(1)
      end

      it 'only clears assignee for conversation with assignee' do
        service.prepare_for_queue!(conversation)
        service.prepare_for_queue!(conversation2)

        expect(conversation.reload.assignee).to be_nil
        expect(conversation2.reload.assignee).to be_nil
      end

      it 'updates both conversations to queued status' do
        service.prepare_for_queue!(conversation)
        service.prepare_for_queue!(conversation2)

        expect(conversation.reload.status).to eq('queued')
        expect(conversation2.reload.status).to eq('queued')
      end
    end

    context 'with different inboxes' do
      let(:inbox2) { create(:inbox, account: account) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox2, status: :open) }
      let(:notification_service2) { instance_double(ChatQueue::Queue::NotificationService) }

      before do
        allow(ChatQueue::Queue::NotificationService).to receive(:new)
          .with(conversation: conversation2).and_return(notification_service2)
        allow(notification_service2).to receive(:send_queue_notification)
      end

      it 'enqueues process job for each inbox separately' do
        service.prepare_for_queue!(conversation)
        service.prepare_for_queue!(conversation2)

        expect(Queue::ProcessQueueJob).to have_received(:perform_later).with(account.id, inbox.id)
        expect(Queue::ProcessQueueJob).to have_received(:perform_later).with(account.id, inbox2.id)
      end
    end

    context 'when called multiple times for same conversation' do
      it 'raises validation error on second call due to uniqueness constraint' do
        service.prepare_for_queue!(conversation)

        expect do
          service.prepare_for_queue!(conversation)
        end.to raise_error(ActiveRecord::RecordInvalid, /Conversation has already been taken/)
      end

      it 'creates only one queue entry' do
        service.prepare_for_queue!(conversation)

        expect do
          service.prepare_for_queue!(conversation)
        rescue StandardError
          nil
        end.not_to change(ConversationQueue, :count)
      end
    end

    context 'when conversation from different account' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:other_conversation) { create(:conversation, account: other_account, inbox: other_inbox) }
      let(:other_service) { described_class.new(account: other_account) }
      let(:other_notification_service) { instance_double(ChatQueue::Queue::NotificationService) }

      before do
        allow(ChatQueue::Queue::NotificationService).to receive(:new)
          .with(conversation: other_conversation).and_return(other_notification_service)
        allow(other_notification_service).to receive(:send_queue_notification)
      end

      it 'creates queue entry with correct account' do
        other_service.prepare_for_queue!(other_conversation)
        queue_entry = ConversationQueue.find_by(conversation: other_conversation)

        expect(queue_entry.account_id).to eq(other_account.id)
      end

      it 'enqueues job for correct account' do
        other_service.prepare_for_queue!(other_conversation)
        expect(Queue::ProcessQueueJob).to have_received(:perform_later)
          .with(other_account.id, other_inbox.id)
      end
    end

    context 'when executing transaction' do
      it 'completes all operations successfully' do
        agent = create(:user, account: account)
        conversation.update!(assignee: agent)

        service.prepare_for_queue!(conversation)

        expect(conversation.reload.assignee).to be_nil
        expect(conversation.status).to eq('queued')
        expect(ConversationQueue.where(conversation: conversation).count).to eq(1)
        expect(notification_service).to have_received(:send_queue_notification)
      end
    end
  end
end
