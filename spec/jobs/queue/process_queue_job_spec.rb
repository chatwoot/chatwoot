require 'rails_helper'

RSpec.describe Queue::ProcessQueueJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account, queue_enabled: true) }
  let(:priority_group) { create(:priority_group, account: account) }
  let(:inbox) { create(:inbox, account: account, priority_group: priority_group) }
  let(:agent1) { create(:user, account: account) }
  let(:agent2) { create(:user, account: account) }
  let(:queue_service) { instance_double(ChatQueue::QueueService) }

  before do
    allow(ChatQueue::QueueService).to receive(:new).and_return(queue_service)
    allow(Rails.logger).to receive(:info)
    allow(queue_service).to receive(:add_to_queue)
  end

  describe '#perform' do
    context 'when account does not exist' do
      it 'stops execution without errors' do
        expect { described_class.new.perform(999, inbox.id) }.not_to raise_error
      end
    end

    context 'when account exists but queue is disabled' do
      before { account.update(queue_enabled: false) }

      it 'stops execution without errors' do
        expect { described_class.new.perform(account.id, inbox.id) }.not_to raise_error
      end
    end

    context 'when queue is empty' do
      before do
        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(0)
      end

      it 'stops execution without processing agents' do
        expect(queue_service).not_to receive(:online_agents_list)

        described_class.new.perform(account.id, inbox.id)
      end
    end

    context 'when no waiting conversations found' do
      before do
        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1)
      end

      it 'stops execution without errors' do
        expect { described_class.new.perform(account.id, inbox.id) }.not_to raise_error
      end
    end

    context 'when no agents are available' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1)
        allow(queue_service).to receive(:online_agents_list).and_return([])
      end

      it 'completes without attempting assignment' do
        expect(queue_service).not_to receive(:assign_specific_from_queue!)

        described_class.new.perform(account.id, inbox.id)
      end
    end

    context 'when agent is missing from database' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1, 0)
        allow(queue_service).to receive(:online_agents_list).and_return([999])
      end

      it 'skips missing agent without errors' do
        expect { described_class.new.perform(account.id, inbox.id) }.not_to raise_error
      end
    end

    context 'when assignment succeeds' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1, 0)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id).and_return(true)
      end

      it 'assigns conversation to agent' do
        expect(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id)

        described_class.new.perform(account.id, inbox.id)
      end
    end

    context 'when first assignment fails but second succeeds' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1, 0)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id, agent2.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id).and_return(false)
        allow(queue_service).to receive(:assign_specific_from_queue!).with(agent2, conversation.id).and_return(true)
      end

      it 'tries both agents in order' do
        expect(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id).ordered
        expect(queue_service).to receive(:assign_specific_from_queue!).with(agent2, conversation.id).ordered

        described_class.new.perform(account.id, inbox.id)
      end
    end

    context 'when all assignment attempts fail' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1, 1)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id, agent2.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).and_return(false)
      end

      it 'schedules next job run' do
        expect do
          described_class.new.perform(account.id, inbox.id)
        end.to have_enqueued_job(described_class).with(account.id, inbox.id).on_queue('default')
      end
    end

    context 'when queue has more items after assignment' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(1, 3)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id).and_return(true)
      end

      it 'schedules next job run' do
        expect do
          described_class.new.perform(account.id, inbox.id)
        end.to have_enqueued_job(described_class).with(account.id, inbox.id).on_queue('default')
      end
    end

    context 'with different priority groups' do
      let(:high_priority_group) { create(:priority_group, account: account, name: 'high') }
      let(:high_priority_inbox) { create(:inbox, account: account, priority_group: high_priority_group) }
      let(:conversation) { create(:conversation, account: account, inbox: high_priority_inbox) }

      before do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: high_priority_inbox,
               status: :waiting)

        allow(queue_service).to receive(:priority_group_for_inbox).with(high_priority_inbox.id).and_return(high_priority_group)
        allow(queue_service).to receive(:queue_size).with(high_priority_inbox.id).and_return(1, 0)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation.id).and_return(true)
      end

      it 'processes queue for correct priority group' do
        expect(queue_service).to receive(:priority_group_for_inbox).with(high_priority_inbox.id)

        described_class.new.perform(account.id, high_priority_inbox.id)
      end
    end

    context 'when ordering conversations by position' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox) }
      let(:queue_record1) do
        create(:conversation_queue,
               account: account,
               conversation: conversation,
               inbox: inbox,
               status: :waiting,
               queued_at: 2.minutes.ago)
      end
      let(:queue_record2) do
        create(:conversation_queue,
               account: account,
               conversation: conversation2,
               inbox: inbox,
               status: :waiting,
               queued_at: 1.minute.ago)
      end

      before do
        # rubocop:disable Rails/SkipsModelValidations
        queue_record1.update_column(:position, 2)
        queue_record2.update_column(:position, 1)
        # rubocop:enable Rails/SkipsModelValidations

        allow(queue_service).to receive(:priority_group_for_inbox).with(inbox.id).and_return(priority_group)
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(2, 1)
        allow(queue_service).to receive(:online_agents_list).and_return([agent1.id])
        allow(queue_service).to receive(:assign_specific_from_queue!).and_return(true)
      end

      it 'picks conversation with lowest position first' do
        expect(queue_service).to receive(:assign_specific_from_queue!).with(agent1, conversation2.id)

        described_class.new.perform(account.id, inbox.id)
      end
    end
  end

  describe 'private methods' do
    let(:job) { described_class.new }

    describe '#find_active_account' do
      it 'returns account when queue is enabled' do
        result = job.send(:find_active_account, account.id)
        expect(result).to eq(account)
      end

      it 'returns nil when account does not exist' do
        result = job.send(:find_active_account, 999)
        expect(result).to be_nil
      end

      it 'returns nil when queue is disabled' do
        account.update(queue_enabled: false)
        result = job.send(:find_active_account, account.id)
        expect(result).to be_nil
      end
    end

    describe '#queue_empty?' do
      it 'returns true when size is zero' do
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(0)
        result = job.send(:queue_empty?, queue_service, account, inbox.id)
        expect(result).to be true
      end

      it 'returns false when size is positive' do
        allow(queue_service).to receive(:queue_size).with(inbox.id).and_return(5)
        result = job.send(:queue_empty?, queue_service, account, inbox.id)
        expect(result).to be false
      end
    end
  end
end
