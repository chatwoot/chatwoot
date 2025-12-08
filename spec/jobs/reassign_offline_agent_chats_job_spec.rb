require 'rails_helper'

RSpec.describe ReassignOfflineAgentChatsJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:offline_agent) { create(:user, account: account, role: :agent) }
  let(:online_agent) { create(:user, account: account, role: :agent) }
  let(:system_user) { create(:account_user, account: account, role: :system) }

  let(:conversation1) do
    create(:conversation,
           inbox: inbox,
           account: account,
           assignee: offline_agent,
           status: :open)
  end

  let(:conversation2) do
    create(:conversation,
           inbox: inbox,
           account: account,
           assignee: offline_agent,
           status: :pending)
  end

  before do
    create(:inbox_member, inbox: inbox, user: offline_agent)
    create(:inbox_member, inbox: inbox, user: online_agent)

    allow(OnlineStatusTracker).to receive(:get_status).and_call_original
  end

  describe '#perform' do
    context 'when agent does not exist' do
      it 'returns early without processing' do
        expect(Conversation).not_to receive(:where)

        described_class.new.perform(99_999, account.id)
      end
    end

    context 'when account does not exist' do
      it 'returns early without processing' do
        expect(Conversation).not_to receive(:where)

        described_class.new.perform(offline_agent.id, 99_999)
      end
    end

    context 'when agent is online' do
      before do
        allow(OnlineStatusTracker).to receive(:get_status)
          .with(account.id, offline_agent.id)
          .and_return('online')
      end

      it 'does not reassign conversations' do
        conversation1

        expect do
          described_class.new.perform(offline_agent.id, account.id)
        end.not_to(change { conversation1.reload.assignee_id })
      end
    end

    context 'when agent is offline' do
      before do
        allow(OnlineStatusTracker).to receive(:get_status) do |_acc_id, user_id|
          user_id == online_agent.id ? 'online' : 'offline'
        end
      end

      context 'when agent has no active conversations' do
        it 'completes without errors' do
          expect do
            described_class.new.perform(offline_agent.id, account.id)
          end.not_to raise_error
        end
      end

      context 'when agent has resolved conversations only' do
        let!(:resolved_conversation) do
          create(:conversation,
                 inbox: inbox,
                 account: account,
                 assignee: offline_agent,
                 status: :resolved)
        end

        it 'does not process resolved conversations' do
          expect do
            described_class.new.perform(offline_agent.id, account.id)
          end.not_to(change { resolved_conversation.reload.assignee_id })
        end
      end

      context 'when there are online agents available' do
        it 'reassigns conversations to online agents' do
          conversation1

          allow(AutoAssignment::AgentAssignmentService).to receive(:new) do |args|
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform) do
              args[:conversation].update!(assignee: online_agent)
            end
            service
          end

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee).to eq(online_agent)
        end

        it 'creates system message about reassignment' do
          conversation1

          allow(AutoAssignment::AgentAssignmentService).to receive(:new) do |args|
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform) do
              args[:conversation].update!(assignee: online_agent)
            end
            service
          end

          expect do
            described_class.new.perform(offline_agent.id, account.id)
          end.to change { conversation1.messages.where(message_type: :activity).count }.by(1)

          activity_message = conversation1.messages.activity.last
          expect(activity_message.content).to include(offline_agent.name)
          expect(activity_message.content).to include('перешёл в офлайн')
        end

        it 'processes multiple conversations' do
          conversation1
          conversation2

          allow(AutoAssignment::AgentAssignmentService).to receive(:new) do |args|
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform) do
              args[:conversation].update!(assignee: online_agent)
            end
            service
          end

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee).to eq(online_agent)
          expect(conversation2.reload.assignee).to eq(online_agent)
        end

        it 'calls AutoAssignment::AgentAssignmentService with correct parameters' do
          conversation1

          expect(AutoAssignment::AgentAssignmentService).to receive(:new).with(
            conversation: conversation1,
            allowed_agent_ids: [online_agent.id]
          ) do
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform) do
              conversation1.update!(assignee: online_agent)
            end
            service
          end

          described_class.new.perform(offline_agent.id, account.id)
        end
      end

      context 'when no online agents are available' do
        before do
          allow(OnlineStatusTracker).to receive(:get_status).and_return('offline')
        end

        it 'unassigns all conversations' do
          conversation1
          conversation2

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
          expect(conversation2.reload.assignee_id).to be_nil
        end

        it 'updates updated_at timestamp' do
          conversation1
          original_time = conversation1.updated_at

          travel_to(1.hour.from_now) do
            described_class.new.perform(offline_agent.id, account.id)
          end

          expect(conversation1.reload.updated_at).to be > original_time
        end
      end

      context 'when reassignment fails' do
        it 'unassigns conversation on error' do
          conversation1

          allow(AutoAssignment::AgentAssignmentService).to receive(:new) do
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform).and_raise(StandardError, 'Test error')
            service
          end

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
        end
      end

      context 'when all agents reached their limit' do
        it 'unassigns conversation if assignee did not change' do
          conversation1

          allow(AutoAssignment::AgentAssignmentService).to receive(:new) do
            service = instance_double(AutoAssignment::AgentAssignmentService)
            allow(service).to receive(:perform) # doesn't change assignee
            service
          end

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
        end
      end

      context 'when conversation inbox has no online members' do
        before do
          inbox.inbox_members.where(user: online_agent).destroy_all
        end

        it 'unassigns conversation' do
          conversation1

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
        end
      end

      context 'with account_id parameter' do
        let(:another_account) { create(:account) }
        let(:another_inbox) { create(:inbox, account: another_account) }
        let(:conversation_another_account) do
          create(:conversation,
                 inbox: another_inbox,
                 account: another_account,
                 assignee: offline_agent,
                 status: :open)
        end

        before do
          create(:account_user, account: another_account, user: offline_agent)
        end

        it 'only processes conversations from specified account' do
          conversation1
          conversation_another_account

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
          expect(conversation_another_account.reload.assignee_id).to eq(offline_agent.id)
        end
      end

      context 'without account_id parameter (nil)' do
        it 'returns early and does nothing when account_id is nil' do
          another_account = create(:account)
          another_inbox = create(:inbox, account: another_account)

          create(:account_user, account: another_account, user: offline_agent)
          create(:inbox_member, inbox: another_inbox, user: offline_agent)

          conversation_another_account = create(:conversation,
                                                inbox: another_inbox,
                                                account: another_account,
                                                assignee: offline_agent,
                                                status: :open)

          conversation1

          tracker_stub = Class.new do
            def self.get_status(_account_id, _user_id)
              'offline'
            end

            def self.get_available_users(_account_id)
              {}
            end
          end

          stub_const('OnlineStatusTracker', tracker_stub)

          expect do
            described_class.new.perform(offline_agent.id, nil)
          end.not_to(change do
            [
              conversation1.reload.assignee_id,
              conversation_another_account.reload.assignee_id
            ]
          end)
        end
      end
    end

    context 'when system message content is generated' do
      before do
        allow(OnlineStatusTracker).to receive(:get_status) do |_acc_id, user_id|
          user_id == online_agent.id ? 'online' : 'offline'
        end
      end

      it 'includes agent name in message' do
        conversation1

        allow(AutoAssignment::AgentAssignmentService).to receive(:new) do |args|
          service = instance_double(AutoAssignment::AgentAssignmentService)
          allow(service).to receive(:perform) do
            args[:conversation].update!(assignee: online_agent)
          end
          service
        end

        described_class.new.perform(offline_agent.id, account.id)

        message = conversation1.messages.activity.last
        expect(message.content).to include(offline_agent.name)
      end

      it 'uses fallback text when agent not found' do
        conv = create(:conversation,
                      inbox: inbox,
                      account: account,
                      status: :open)
        # rubocop:disable Rails/SkipsModelValidations
        conv.update_column(:assignee_id, 99_999)
        # rubocop:enable Rails/SkipsModelValidations

        job = described_class.new
        job.send(:create_system_message, conv)

        message = conv.messages.activity.last
        expect(message).not_to be_nil
        expect(message.content).to include('неизвестного оператора')
      end
    end

    context 'when detecting agent status' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: inbox, user: other_agent)
      end

      context 'when status is nil and auto_offline is true' do
        before do
          account_user = offline_agent.account_users.find_or_create_by!(account: account) do |au|
            au.role = :agent
          end
          allow(account_user).to receive(:auto_offline?).and_return(true)

          allow(OnlineStatusTracker).to receive(:get_status) do |_acc_id, user_id|
            user_id == online_agent.id ? 'online' : 'offline'
          end

          account_users = instance_double(ActiveRecord::Associations::CollectionProxy)
          allow(offline_agent).to receive(:account_users).and_return(account_users)
          allow(account_users).to receive(:find_by).with(account_id: account.id).and_return(account_user)
        end

        it 'treats agent as offline' do
          conversation1

          described_class.new.perform(offline_agent.id, account.id)

          expect(conversation1.reload.assignee_id).to be_nil
        end
      end

      context 'when status is nil and auto_offline is false' do
        it 'treats agent as offline and unassigns conversations' do
          conversation1

          account_user = offline_agent.account_users.find_or_create_by!(account: account) do |au|
            au.role = :agent
          end
          allow(account_user).to receive(:auto_offline?).and_return(false)

          allow(User).to receive(:find_by).with(id: offline_agent.id).and_return(offline_agent)
          allow(offline_agent).to receive(:account_users).and_return(
            instance_double(ActiveRecord::Associations::CollectionProxy, find_by: account_user)
          )

          agent_id = offline_agent.id

          tracker_stub = Class.new do
            define_singleton_method(:get_status) do |_acc_id, user_id|
              user_id == agent_id ? nil : 'offline'
            end

            define_singleton_method(:get_available_users) do |_account_id|
              {}
            end
          end

          stub_const('OnlineStatusTracker', tracker_stub)

          expect do
            described_class.new.perform(offline_agent.id, account.id)
          end.to change { conversation1.reload.assignee_id }.from(offline_agent.id).to(nil)
        end
      end
    end
  end
end
