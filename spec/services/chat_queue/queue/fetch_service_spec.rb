require 'rails_helper'

RSpec.describe ChatQueue::Queue::FetchService do
  let(:account) { create(:account) }
  let(:priority_group) { create(:priority_group, name: 'high') }
  let(:inbox) { create(:inbox, account: account, priority_group: priority_group) }
  let(:service) { described_class.new(account: account) }

  describe '#fetch_queue_entry' do
    context 'when there are waiting entries' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }

      it 'returns the first entry ordered by position' do
        entry1 = create(:conversation_queue, :waiting,
                        conversation: conversation1,
                        account: account,
                        inbox: inbox,
                        queued_at: 10.minutes.ago)
        entry2 = create(:conversation_queue, :waiting,
                        conversation: conversation2,
                        account: account,
                        inbox: inbox,
                        queued_at: 5.minutes.ago)

        result = service.fetch_queue_entry(inbox.id)

        expect(result).to eq(entry1)
        expect(entry1.position).to eq(1)
        expect(entry2.position).to eq(2)
      end

      it 'uses queued_at as secondary sort when positions are equal' do
        entry1 = create(:conversation_queue, :waiting,
                        conversation: conversation1,
                        account: account,
                        inbox: inbox,
                        queued_at: 10.minutes.ago)
        create(:conversation_queue, :waiting,
               conversation: conversation2,
               account: account,
               inbox: inbox,
               queued_at: 5.minutes.ago)

        result = service.fetch_queue_entry(inbox.id)

        expect(result).to eq(entry1)
      end

      it 'only returns entries for the specified priority group' do
        other_group = create(:priority_group, name: 'low')
        other_inbox = create(:inbox, account: account, priority_group: other_group)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox,
               position: 2,
               queued_at: 10.minutes.ago)
        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: account,
               inbox: other_inbox,
               position: 1,
               queued_at: 5.minutes.ago)

        result = service.fetch_queue_entry(inbox.id)

        expect(result.conversation).to eq(conversation1)
      end

      it 'only returns waiting entries' do
        create(:conversation_queue, :assigned,
               conversation: conversation1,
               account: account,
               inbox: inbox,
               position: 1,
               queued_at: 10.minutes.ago)
        entry2 = create(:conversation_queue, :waiting,
                        conversation: conversation2,
                        account: account,
                        inbox: inbox,
                        position: 2,
                        queued_at: 5.minutes.ago)

        result = service.fetch_queue_entry(inbox.id)

        expect(result).to eq(entry2)
      end

      it 'only returns entries for the current account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account, priority_group: priority_group)
        other_conversation = create(:conversation, account: other_account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: other_account,
               inbox: other_inbox,
               position: 1,
               queued_at: 10.minutes.ago)
        entry2 = create(:conversation_queue, :waiting,
                        conversation: conversation1,
                        account: account,
                        inbox: inbox,
                        position: 2,
                        queued_at: 5.minutes.ago)

        result = service.fetch_queue_entry(inbox.id)

        expect(result).to eq(entry2)
      end
    end

    context 'when no entries exist' do
      it 'returns nil' do
        expect(service.fetch_queue_entry(inbox.id)).to be_nil
      end

      it 'returns nil when only non-waiting entries exist' do
        conversation = create(:conversation, account: account, inbox: inbox)
        create(:conversation_queue, :assigned,
               conversation: conversation,
               account: account,
               inbox: inbox)

        expect(service.fetch_queue_entry(inbox.id)).to be_nil
      end
    end

    context 'with multiple priority groups' do
      let(:high_group) { create(:priority_group, name: 'high') }
      let(:low_group) { create(:priority_group, name: 'low') }
      let(:high_inbox) { create(:inbox, account: account, priority_group: high_group) }
      let(:low_inbox) { create(:inbox, account: account, priority_group: low_group) }

      it 'fetches entries only from requested priority group' do
        high_conversation = create(:conversation, account: account, inbox: high_inbox)
        low_conversation = create(:conversation, account: account, inbox: low_inbox)

        high_entry = create(:conversation_queue, :waiting,
                            conversation: high_conversation,
                            account: account,
                            inbox: high_inbox,
                            position: 1)
        create(:conversation_queue, :waiting,
               conversation: low_conversation,
               account: account,
               inbox: low_inbox,
               position: 1)

        result = service.fetch_queue_entry(high_inbox.id)

        expect(result).to eq(high_entry)
      end
    end

    context 'with mixed statuses' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation3) { create(:conversation, account: account, inbox: inbox) }

      it 'ignores left and assigned entries' do
        create(:conversation_queue, :left,
               conversation: conversation1,
               account: account,
               inbox: inbox,
               position: 1)
        create(:conversation_queue, :assigned,
               conversation: conversation2,
               account: account,
               inbox: inbox,
               position: 2)
        entry3 = create(:conversation_queue, :waiting,
                        conversation: conversation3,
                        account: account,
                        inbox: inbox,
                        position: 3)

        result = service.fetch_queue_entry(inbox.id)

        expect(result).to eq(entry3)
      end
    end
  end

  describe '#fetch_specific_entry' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    context 'when waiting entry exists' do
      it 'returns the specific queue entry' do
        entry = create(:conversation_queue, :waiting,
                       conversation: conversation,
                       account: account,
                       inbox: inbox)

        result = service.fetch_specific_entry(conversation.id)

        expect(result).to eq(entry)
      end

      it 'returns entry regardless of account or priority group' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)
        other_conversation = create(:conversation, account: other_account, inbox: other_inbox)
        other_service = described_class.new(account: other_account)

        entry = create(:conversation_queue, :waiting,
                       conversation: other_conversation,
                       account: other_account,
                       inbox: other_inbox)

        result = other_service.fetch_specific_entry(other_conversation.id)

        expect(result).to eq(entry)
      end
    end

    context 'when entry does not exist' do
      it 'returns nil' do
        expect(service.fetch_specific_entry(conversation.id)).to be_nil
      end
    end

    context 'when entry exists but not waiting' do
      it 'returns nil for assigned entry' do
        create(:conversation_queue, :assigned,
               conversation: conversation,
               account: account,
               inbox: inbox)

        expect(service.fetch_specific_entry(conversation.id)).to be_nil
      end

      it 'returns nil for left entry' do
        create(:conversation_queue, :left,
               conversation: conversation,
               account: account,
               inbox: inbox)

        expect(service.fetch_specific_entry(conversation.id)).to be_nil
      end
    end

    context 'with multiple entries for different conversations' do
      it 'returns the correct waiting entry' do
        other_conversation = create(:conversation, account: account, inbox: inbox)

        create(:conversation_queue, :left,
               conversation: other_conversation,
               account: account,
               inbox: inbox,
               queued_at: 1.hour.ago,
               left_at: 30.minutes.ago)
        entry = create(:conversation_queue, :waiting,
                       conversation: conversation,
                       account: account,
                       inbox: inbox)

        result = service.fetch_specific_entry(conversation.id)

        expect(result).to eq(entry)
      end
    end

    context 'with non-existent conversation id' do
      it 'returns nil' do
        expect(service.fetch_specific_entry(999_999)).to be_nil
      end
    end
  end

  describe '#next_in_queue' do
    context 'when entries exist' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }

      it 'returns the conversation of the first queue entry' do
        entry1 = create(:conversation_queue, :waiting,
                        conversation: conversation1,
                        account: account,
                        inbox: inbox)
        entry2 = create(:conversation_queue, :waiting,
                        conversation: conversation2,
                        account: account,
                        inbox: inbox)

        result = service.next_in_queue(inbox.id)

        expect(result).to eq(conversation1)
        expect(entry1.position).to be < entry2.position
      end

      it 'uses default scope ordering when no explicit order' do
        entry1 = create(:conversation_queue, :waiting,
                        conversation: conversation1,
                        account: account,
                        inbox: inbox,
                        queued_at: 10.minutes.ago)
        create(:conversation_queue, :waiting,
               conversation: conversation2,
               account: account,
               inbox: inbox,
               queued_at: 5.minutes.ago)

        result = service.next_in_queue(inbox.id)

        expect(result).to eq(entry1.conversation)
      end

      it 'only returns conversation from specified priority group' do
        other_group = create(:priority_group, name: 'low')
        other_inbox = create(:inbox, account: account, priority_group: other_group)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: account,
               inbox: other_inbox,
               position: 1)
        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox,
               position: 2)

        result = service.next_in_queue(inbox.id)

        expect(result).to eq(conversation1)
      end

      it 'only returns conversation from current account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account, priority_group: priority_group)
        other_conversation = create(:conversation, account: other_account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: other_account,
               inbox: other_inbox)
        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox)

        result = service.next_in_queue(inbox.id)

        expect(result).to eq(conversation1)
      end
    end

    context 'when no entries exist' do
      it 'returns nil' do
        expect(service.next_in_queue(inbox.id)).to be_nil
      end

      it 'returns nil when only non-waiting entries exist' do
        conversation = create(:conversation, account: account, inbox: inbox)
        create(:conversation_queue, :assigned,
               conversation: conversation,
               account: account,
               inbox: inbox)

        expect(service.next_in_queue(inbox.id)).to be_nil
      end
    end
  end

  describe '#queue_size' do
    context 'when entries exist' do
      let(:conversation1) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation3) { create(:conversation, account: account, inbox: inbox) }

      it 'returns the count of waiting entries for the priority group' do
        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :waiting,
               conversation: conversation2,
               account: account,
               inbox: inbox)

        expect(service.queue_size(inbox.id)).to eq(2)
      end

      it 'excludes non-waiting entries' do
        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :assigned,
               conversation: conversation2,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :left,
               conversation: conversation3,
               account: account,
               inbox: inbox)

        expect(service.queue_size(inbox.id)).to eq(1)
      end

      it 'only counts entries for specified priority group' do
        other_group = create(:priority_group, name: 'low')
        other_inbox = create(:inbox, account: account, priority_group: other_group)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: account,
               inbox: other_inbox)

        expect(service.queue_size(inbox.id)).to eq(1)
      end

      it 'only counts entries for current account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account, priority_group: priority_group)
        other_conversation = create(:conversation, account: other_account, inbox: other_inbox)

        create(:conversation_queue, :waiting,
               conversation: conversation1,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               account: other_account,
               inbox: other_inbox)

        expect(service.queue_size(inbox.id)).to eq(1)
      end
    end

    context 'when no entries exist' do
      it 'returns 0' do
        expect(service.queue_size(inbox.id)).to eq(0)
      end

      it 'returns 0 when only non-waiting entries exist' do
        conversation = create(:conversation, account: account, inbox: inbox)
        create(:conversation_queue, :assigned,
               conversation: conversation,
               account: account,
               inbox: inbox)

        expect(service.queue_size(inbox.id)).to eq(0)
      end
    end

    context 'with large queue' do
      it 'returns correct count for many entries' do
        10.times do
          conversation = create(:conversation, account: account, inbox: inbox)
          create(:conversation_queue, :waiting,
                 conversation: conversation,
                 account: account,
                 inbox: inbox)
        end

        expect(service.queue_size(inbox.id)).to eq(10)
      end
    end
  end

  describe '#priority_group_for_inbox' do
    it 'returns the inbox priority group' do
      result = service.priority_group_for_inbox(inbox.id)

      expect(result).to eq(priority_group)
    end

    it 'caches the result for multiple calls' do
      expect(Inbox).to receive(:find).once.and_return(inbox)

      service.priority_group_for_inbox(inbox.id)
      service.priority_group_for_inbox(inbox.id)
      service.priority_group_for_inbox(inbox.id)
    end

    it 'caches results per inbox_id' do
      other_group = create(:priority_group, name: 'low')
      other_inbox = create(:inbox, account: account, priority_group: other_group)

      result1 = service.priority_group_for_inbox(inbox.id)
      result2 = service.priority_group_for_inbox(other_inbox.id)

      expect(result1).to eq(priority_group)
      expect(result2).to eq(other_group)
      expect(result1).not_to eq(result2)
    end

    it 'works across multiple service instances' do
      service1 = described_class.new(account: account)
      service2 = described_class.new(account: account)

      result1 = service1.priority_group_for_inbox(inbox.id)
      result2 = service2.priority_group_for_inbox(inbox.id)

      expect(result1).to eq(priority_group)
      expect(result2).to eq(priority_group)
    end

    context 'when inbox does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          service.priority_group_for_inbox(999_999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'integration scenarios' do
    context 'with complex queue state' do
      let(:high_group) { create(:priority_group, name: 'high') }
      let(:low_group) { create(:priority_group, name: 'low') }
      let(:high_inbox) { create(:inbox, account: account, priority_group: high_group) }
      let(:low_inbox) { create(:inbox, account: account, priority_group: low_group) }

      it 'handles multiple priority groups correctly' do
        high_conv1 = create(:conversation, account: account, inbox: high_inbox)
        high_conv2 = create(:conversation, account: account, inbox: high_inbox)
        low_conv1 = create(:conversation, account: account, inbox: low_inbox)

        create(:conversation_queue, :waiting,
               conversation: high_conv1,
               account: account,
               inbox: high_inbox,
               position: 1)
        create(:conversation_queue, :waiting,
               conversation: high_conv2,
               account: account,
               inbox: high_inbox,
               position: 2)
        create(:conversation_queue, :waiting,
               conversation: low_conv1,
               account: account,
               inbox: low_inbox,
               position: 1)

        expect(service.queue_size(high_inbox.id)).to eq(2)
        expect(service.queue_size(low_inbox.id)).to eq(1)
        expect(service.next_in_queue(high_inbox.id)).to eq(high_conv1)
        expect(service.next_in_queue(low_inbox.id)).to eq(low_conv1)
      end
    end

    context 'with multiple accounts' do
      it 'isolates data between accounts' do
        account2 = create(:account)
        inbox2 = create(:inbox, account: account2, priority_group: priority_group)
        service2 = described_class.new(account: account2)

        conv1 = create(:conversation, account: account, inbox: inbox)
        conv2 = create(:conversation, account: account2, inbox: inbox2)

        create(:conversation_queue, :waiting,
               conversation: conv1,
               account: account,
               inbox: inbox)
        create(:conversation_queue, :waiting,
               conversation: conv2,
               account: account2,
               inbox: inbox2)

        expect(service.queue_size(inbox.id)).to eq(1)
        expect(service2.queue_size(inbox2.id)).to eq(1)
        expect(service.next_in_queue(inbox.id)).to eq(conv1)
        expect(service2.next_in_queue(inbox2.id)).to eq(conv2)
      end
    end
  end
end
