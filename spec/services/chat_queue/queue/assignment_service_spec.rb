require 'rails_helper'

RSpec.describe ChatQueue::Queue::AssignmentService do
  subject(:service) { described_class.new(account: account, entry: entry, agent: agent) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:entry) { create(:conversation_queue, conversation: conversation, status: :waiting) }

  let(:notification_service) { instance_double(ChatQueue::Queue::NotificationService) }
  let(:limits_service) { instance_double(ChatQueue::Agents::LimitsService) }

  before do
    allow(ChatQueue::Queue::NotificationService).to receive(:new)
      .with(conversation: conversation).and_return(notification_service)
    allow(notification_service).to receive(:send_assigned_notification)

    allow(ChatQueue::Agents::LimitsService).to receive(:new)
      .with(account: account).and_return(limits_service)
  end

  describe '#assign!' do
    context 'when entry is already assigned' do
      before { entry.update!(status: :assigned, assigned_at: 1.minute.ago) }

      it 'does not reassign and returns the conversation' do
        expect { service.assign! }.not_to(change { conversation.reload.assignee_id })

        result = service.assign!
        expect(result).to eq(conversation)
        expect(entry.reload.status).to eq('assigned')
      end

      it 'does not send notification' do
        service.assign!
        expect(notification_service).not_to have_received(:send_assigned_notification)
      end
    end

    context 'when conversation already has an assignee' do
      let(:existing_agent) { create(:user, account: account) }

      before { conversation.update!(assignee: existing_agent) }

      it 'does not reassign and returns the conversation' do
        result = service.assign!

        expect(result).to eq(conversation)
        expect(conversation.reload.assignee).to eq(existing_agent)
        expect(entry.reload.status).to eq('waiting')
      end

      it 'does not send notification' do
        service.assign!
        expect(notification_service).not_to have_received(:send_assigned_notification)
      end
    end

    context 'when agent has no limit set' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(nil)
      end

      it 'assigns successfully regardless of active conversations count' do
        create_list(:conversation, 10, account: account, assignee: agent, status: :open)

        result = service.assign!

        expect(result).to eq(conversation)
        expect(entry.reload.status).to eq('assigned')
        expect(entry.assigned_at).not_to be_nil
        expect(conversation.reload.assignee).to eq(agent)
        expect(conversation.status).to eq('open')
      end
    end

    context 'when agent is at limit' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(2)
        create_list(:conversation, 2, account: account, assignee: agent, status: :open)
      end

      it 'does not assign and returns nil' do
        result = service.assign!

        expect(result).to be_nil
        expect(entry.reload.status).to eq('waiting')
        expect(conversation.reload.assignee).to be_nil
      end

      it 'does not send notification' do
        service.assign!
        expect(notification_service).not_to have_received(:send_assigned_notification)
      end
    end

    context 'when agent is below limit' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(3)
        create_list(:conversation, 2, account: account, assignee: agent, status: :open)
      end

      it 'assigns successfully' do
        result = service.assign!

        expect(result).to eq(conversation)
        expect(entry.reload.status).to eq('assigned')
        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when assignment is valid' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(5)
      end

      it 'assigns entry and updates conversation' do
        freeze_time do
          result = service.assign!

          expect(result).to eq(conversation)

          entry.reload
          expect(entry.status).to eq('assigned')
          expect(entry.assigned_at).to be_within(1.second).of(Time.current)

          conversation.reload
          expect(conversation.assignee).to eq(agent)
          expect(conversation.status).to eq('open')
          expect(conversation.updated_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'sends assignment notification' do
        service.assign!
        expect(notification_service).to have_received(:send_assigned_notification).once
      end

      it 'updates queue statistics' do
        entry.update!(created_at: 5.minutes.ago)

        expect do
          service.assign!
        end.to change(QueueStatistic, :count).by(1)

        stat = QueueStatistic.last
        expect(stat.account_id).to eq(account.id)
      end

      it 'is idempotent when called multiple times' do
        service.assign!
        first_assigned_at = entry.reload.assigned_at

        service.assign!

        expect(entry.reload.assigned_at).to eq(first_assigned_at)
        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when only resolved conversations exist for agent' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(2)
        create_list(:conversation, 5, account: account, assignee: agent, status: :resolved)
      end

      it 'assigns successfully as resolved conversations do not count' do
        result = service.assign!

        expect(result).to eq(conversation)
        expect(entry.reload.status).to eq('assigned')
        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when conversation belongs to different account' do
      let(:other_account) { create(:account) }
      let(:other_conversation) { create(:conversation, account: other_account) }
      let(:other_entry) { create(:conversation_queue, conversation: other_conversation, status: :waiting) }
      let(:other_notification_service) { instance_double(ChatQueue::Queue::NotificationService) }
      let(:other_limits_service) { instance_double(ChatQueue::Agents::LimitsService) }
      let(:other_service) { described_class.new(account: other_account, entry: other_entry, agent: agent) }

      before do
        allow(ChatQueue::Queue::NotificationService).to receive(:new)
          .with(conversation: other_conversation).and_return(other_notification_service)
        allow(other_notification_service).to receive(:send_assigned_notification)

        allow(ChatQueue::Agents::LimitsService).to receive(:new)
          .with(account: other_account).and_return(other_limits_service)
        allow(other_limits_service).to receive(:limit_for).with(agent.id).and_return(2)

        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(2)
        create_list(:conversation, 2, account: account, assignee: agent, status: :open)
      end

      it 'does not count conversations from different account' do
        result = other_service.assign!

        expect(result).to eq(other_conversation)
        expect(other_entry.reload.status).to eq('assigned')
      end
    end

    context 'when transaction rollback occurs due to limit' do
      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(1)
        create(:conversation, account: account, assignee: agent, status: :open)
      end

      it 'does not persist any changes' do
        expect do
          service.assign!
        end.not_to(change { [entry.reload.status, conversation.reload.assignee_id] })
      end

      it 'does not send notification when rollback occurs' do
        service.assign!
        expect(notification_service).not_to have_received(:send_assigned_notification)
      end
    end

    context 'when multiple assignments attempt simultaneously' do
      let(:agent2) { create(:user, account: account) }
      let(:service2) { described_class.new(account: account, entry: entry, agent: agent2) }

      before do
        allow(limits_service).to receive(:limit_for).with(agent.id).and_return(5)
        allow(limits_service).to receive(:limit_for).with(agent2.id).and_return(5)
      end

      it 'only one assignment succeeds due to database lock' do
        result1 = service.assign!
        expect(result1).to eq(conversation)
        expect(entry.reload.status).to eq('assigned')

        result2 = service2.assign!
        expect(result2).to eq(conversation)
        expect(conversation.reload.assignee).to eq(agent)
      end
    end
  end
end
