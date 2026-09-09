require 'rails_helper'

RSpec.describe ChatQueue::Queue::RemovalService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(account: account, conversation: conversation) }

  describe '#remove!' do
    context 'when a waiting queue entry exists' do
      let!(:entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 5.minutes.ago)
      end

      it 'updates the entry status to left and sets left_at' do
        freeze_time do
          result = service.remove!

          expect(result).to eq(entry.reload)
          expect(entry.status).to eq('left')
          expect(entry.left_at).to eq(Time.current)
        end
      end

      it 'updates statistics for left queue entry' do
        freeze_time do
          service.remove!

          stats = QueueStatistic.find_by(account_id: account.id, date: Date.current)
          expect(stats).not_to be_nil
          expect(stats.total_left).to eq(1)
          expect(stats.total_queued).to eq(1)
        end
      end

      it 'persists changes to database' do
        service.remove!

        persisted_entry = ConversationQueue.find(entry.id)
        expect(persisted_entry.status).to eq('left')
        expect(persisted_entry.left_at).not_to be_nil
      end

      it 'does not affect other queue entries' do
        other_conversation = create(:conversation, account: account, inbox: inbox)
        other_entry = create(:conversation_queue, :waiting,
                             conversation: other_conversation)

        service.remove!

        expect(other_entry.reload.status).to eq('waiting')
        expect(other_entry.left_at).to be_nil
      end
    end

    context 'when no waiting queue entry exists' do
      it 'returns nil' do
        expect(service.remove!).to be_nil
      end

      it 'does not create any queue entries' do
        expect { service.remove! }.not_to change(ConversationQueue, :count)
      end

      it 'does not update statistics' do
        expect { service.remove! }.not_to change(QueueStatistic, :count)
      end
    end

    context 'when queue entry exists but not in waiting status' do
      let!(:assigned_entry) do
        create(:conversation_queue, :assigned,
               conversation: conversation)
      end

      it 'returns nil as only waiting entries can be removed' do
        expect(service.remove!).to be_nil
      end

      it 'does not modify the assigned entry' do
        service.remove!

        expect(assigned_entry.reload.status).to eq('assigned')
        expect(assigned_entry.left_at).to be_nil
      end
    end

    context 'when multiple queue entries exist for same conversation' do
      let(:other_conversation) { create(:conversation, account: account, inbox: inbox) }

      let!(:old_entry) do
        create(:conversation_queue, :left,
               conversation: other_conversation,
               queued_at: 1.hour.ago,
               left_at: 30.minutes.ago)
      end

      let!(:current_entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 5.minutes.ago)
      end

      it 'only removes the waiting entry for specified conversation' do
        service.remove!

        expect(current_entry.reload.status).to eq('left')
        expect(old_entry.reload.status).to eq('left')
        expect(old_entry.reload.left_at).to eq(old_entry.left_at)
      end
    end

    context 'when database update fails' do
      let(:entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation)
      end

      before do
        allow(entry).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(entry))
        allow(ConversationQueue).to receive(:find_by).and_return(entry)
      end

      it 'returns nil and does not raise error' do
        expect { service.remove! }.not_to raise_error
        expect(service.remove!).to be_nil
      end

      it 'does not persist any changes' do
        service.remove!

        expect(entry.reload.status).to eq('waiting')
        expect(entry.left_at).to be_nil
      end
    end

    context 'when statistics update fails' do
      let!(:entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation)
      end

      before do
        allow(QueueStatistic).to receive(:update_statistics_for)
          .and_raise(StandardError.new('Stats error'))
      end

      it 'returns nil and does not raise error' do
        expect { service.remove! }.not_to raise_error
        expect(service.remove!).to be_nil
      end

      it 'entry is updated even if statistics fail' do
        service.remove!

        reloaded_entry = ConversationQueue.find_by(id: entry.id)
        expect(reloaded_entry.status).to eq('left')
        expect(reloaded_entry.left_at).not_to be_nil
      end
    end

    context 'with different accounts' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:other_conversation) { create(:conversation, account: other_account, inbox: other_inbox) }
      let(:other_service) { described_class.new(account: other_account, conversation: other_conversation) }

      let!(:entry1) do
        create(:conversation_queue, :waiting,
               conversation: conversation)
      end

      let!(:entry2) do
        create(:conversation_queue, :waiting,
               conversation: other_conversation)
      end

      it 'removes only entries for the specified account' do
        service.remove!

        expect(entry1.reload.status).to eq('left')
        expect(entry2.reload.status).to eq('waiting')
      end

      it 'updates statistics only for the specified account' do
        service.remove!
        other_service.remove!

        stats1 = QueueStatistic.find_by(account_id: account.id, date: Date.current)
        stats2 = QueueStatistic.find_by(account_id: other_account.id, date: Date.current)

        expect(stats1.total_left).to eq(1)
        expect(stats2.total_left).to eq(1)
      end
    end

    context 'with concurrent removals' do
      let!(:entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation)
      end

      it 'handles race condition gracefully' do
        service1 = described_class.new(account: account, conversation: conversation)
        service2 = described_class.new(account: account, conversation: conversation)

        result1 = service1.remove!
        result2 = service2.remove!

        expect(result1).not_to be_nil
        expect(result2).to be_nil
        expect(entry.reload.status).to eq('left')
      end
    end

    context 'with conversation having nil id' do
      it 'handles gracefully' do
        allow(conversation).to receive(:id).and_return(nil)

        expect { service.remove! }.not_to raise_error
        expect(service.remove!).to be_nil
      end
    end

    context 'with very old queue entries' do
      it 'processes them correctly' do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 1.year.ago)

        freeze_time do
          service.remove!

          stats = QueueStatistic.find_by(account_id: account.id, date: Date.current)
          expect(stats.total_left).to eq(1)
          expect(stats.total_queued).to eq(1)
          expect(stats.average_wait_time_seconds).to eq(0)
        end
      end
    end

    context 'with multiple removals of same conversation' do
      it 'handles gracefully' do
        entry = create(:conversation_queue, :waiting,
                       conversation: conversation)

        result1 = service.remove!
        result2 = service.remove!

        expect(result1).not_to be_nil
        expect(result2).to be_nil
        expect(entry.reload.status).to eq('left')
      end
    end

    context 'with service using different conversation instances' do
      it 'works correctly' do
        entry = create(:conversation_queue, :waiting,
                       conversation: conversation)

        fresh_conversation = Conversation.find(conversation.id)
        fresh_service = described_class.new(account: account, conversation: fresh_conversation)

        result = fresh_service.remove!

        expect(result).not_to be_nil
        expect(entry.reload.status).to eq('left')
      end
    end

    context 'with statistics creation' do
      it 'creates statistics record if not exists' do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 5.minutes.ago)

        expect do
          service.remove!
        end.to change { QueueStatistic.where(account_id: account.id, date: Date.current).count }.by(1)
      end

      it 'increments counters correctly' do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 5.minutes.ago)

        service.remove!

        stats = QueueStatistic.find_by(account_id: account.id, date: Date.current)
        expect(stats.total_queued).to eq(1)
        expect(stats.total_left).to eq(1)
        expect(stats.total_assigned).to eq(0)
      end

      it 'does not update average_wait_time for left entries' do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 5.minutes.ago)

        freeze_time do
          service.remove!

          stats = QueueStatistic.find_by(account_id: account.id, date: Date.current)
          expect(stats.average_wait_time_seconds).to eq(0)
        end
      end
    end

    context 'with multiple removals on same day' do
      it 'accumulates statistics correctly' do
        create(:conversation_queue, :waiting,
               conversation: conversation,
               queued_at: 10.minutes.ago)
        service.remove!

        stats = QueueStatistic.find_by(account_id: account.id, date: Date.current)
        expect(stats.total_left).to eq(1)
        expect(stats.total_queued).to eq(1)

        other_conversation = create(:conversation, account: account, inbox: inbox)
        create(:conversation_queue, :waiting,
               conversation: other_conversation,
               queued_at: 5.minutes.ago)
        other_service = described_class.new(account: account, conversation: other_conversation)
        other_service.remove!

        stats.reload
        expect(stats.total_left).to eq(2)
        expect(stats.total_queued).to eq(2)
      end
    end

    context 'when catching StandardError exceptions' do
      let(:entry) do
        create(:conversation_queue, :waiting,
               conversation: conversation)
      end

      it 'catches RuntimeError' do
        allow(entry).to receive(:update!).and_raise(RuntimeError.new('Unexpected error'))
        allow(ConversationQueue).to receive(:find_by).and_return(entry)

        expect { service.remove! }.not_to raise_error
        expect(service.remove!).to be_nil
      end

      it 'catches ActiveRecord exceptions' do
        allow(entry).to receive(:update!).and_raise(ActiveRecord::StatementInvalid.new('DB error'))
        allow(ConversationQueue).to receive(:find_by).and_return(entry)

        expect { service.remove! }.not_to raise_error
        expect(service.remove!).to be_nil
      end
    end
  end
end
