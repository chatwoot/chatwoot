require 'rails_helper'

RSpec.describe ChatQueue::Queue::ValidationService do
  let(:account) { create(:account, queue_enabled: true) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(account: account) }

  describe '#valid_for_queue?' do
    context 'when queue is disabled for account' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        account.update!(queue_enabled: false)
        ConversationQueue.where(conversation: conversation).delete_all
      end

      it 'returns false' do
        expect(service.valid_for_queue?(conversation)).to be(false)
      end

      it 'returns false even if conversation not in queue' do
        expect(ConversationQueue.exists?(conversation: conversation)).to be(false)
        expect(service.valid_for_queue?(conversation)).to be(false)
      end
    end

    context 'when queue is enabled for account' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        account.update!(queue_enabled: true)
        ConversationQueue.where(conversation: conversation).delete_all
      end

      it 'returns true when conversation not in queue' do
        expect(service.valid_for_queue?(conversation)).to be(true)
      end
    end

    context 'when conversation is already in queue with waiting status' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        ConversationQueue.where(conversation: conversation).delete_all
        create(:conversation_queue, :waiting, conversation: conversation)
      end

      it 'returns false' do
        expect(service.valid_for_queue?(conversation)).to be(false)
      end

      it 'does not allow duplicate queue entries' do
        expect(ConversationQueue.where(conversation: conversation, status: :waiting).count).to eq(1)
        expect(service.valid_for_queue?(conversation)).to be(false)
      end
    end

    context 'when conversation has non-waiting queue entry' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        ConversationQueue.where(conversation: conversation).delete_all
        create(:conversation_queue, :assigned, conversation: conversation)
      end

      it 'returns true as only waiting status blocks queueing' do
        expect(service.valid_for_queue?(conversation)).to be(true)
      end
    end

    context 'with multiple conversations' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }

      before do
        ConversationQueue.where(conversation: [conversation1, conversation2]).delete_all
        create(:conversation_queue, :waiting, conversation: conversation1)
      end

      it 'validates each conversation independently' do
        expect(service.valid_for_queue?(conversation1)).to be(false)
        expect(service.valid_for_queue?(conversation2)).to be(true)
      end
    end

    context 'when conversation belongs to different account' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:other_account) { create(:account, queue_enabled: true) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:conversation2) { create(:conversation, account: other_account, inbox: other_inbox) }
      let(:other_service) { described_class.new(account: other_account) }

      before do
        ConversationQueue.where(conversation: [conversation1, conversation2]).delete_all
        create(:conversation_queue, :waiting, conversation: conversation1)
      end

      it 'validates only within the same account' do
        expect(service.valid_for_queue?(conversation1)).to be(false)
        expect(other_service.valid_for_queue?(conversation2)).to be(true)
      end
    end

    context 'when queue enabled changes dynamically' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        ConversationQueue.where(conversation: conversation).delete_all
      end

      it 'respects current queue_enabled state' do
        account.update!(queue_enabled: true)
        expect(service.valid_for_queue?(conversation)).to be(true)

        account.update!(queue_enabled: false)
        expect(service.valid_for_queue?(conversation)).to be(false)

        account.update!(queue_enabled: true)
        expect(service.valid_for_queue?(conversation)).to be(true)
      end
    end

    context 'when conversation removed from queue' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        ConversationQueue.where(conversation: conversation).delete_all
        queue_entry = create(:conversation_queue, :waiting, conversation: conversation)
        queue_entry.destroy
      end

      it 'returns true after removal' do
        expect(ConversationQueue.exists?(conversation: conversation, status: :waiting)).to be(false)
        expect(service.valid_for_queue?(conversation)).to be(true)
      end
    end

    context 'when conversation queue status changes' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:queue_entry) do
        ConversationQueue.where(conversation: conversation).delete_all
        create(:conversation_queue, :waiting, conversation: conversation)
      end

      it 'returns true when status changed from waiting to assigned' do
        queue_entry.update!(status: :assigned)
        expect(service.valid_for_queue?(conversation)).to be(true)
      end

      it 'returns false when status is waiting' do
        queue_entry
        expect(service.valid_for_queue?(conversation)).to be(false)
      end
    end

    context 'with edge cases' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      it 'handles conversation with no queue entries' do
        ConversationQueue.where(conversation: conversation).delete_all

        expect(ConversationQueue.where(conversation: conversation).count).to eq(0)
        expect(service.valid_for_queue?(conversation)).to be(true)
      end

      it 'handles conversation with completed status entry' do
        ConversationQueue.where(conversation: conversation).delete_all
        create(:conversation_queue, :left, conversation: conversation)

        expect(service.valid_for_queue?(conversation)).to be(true)
      end
    end
  end
end
