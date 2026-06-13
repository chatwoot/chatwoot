require 'rails_helper'

describe NotificationBuilder do
  describe '#perform with custom role permissions' do
    let!(:account) { create(:account) }
    let!(:agent) { create(:user, account: account, role: :agent) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:account_user) { agent.account_users.find_by(account: account) }

    before do
      create(:inbox_member, user: agent, inbox: inbox)
      notification_setting = agent.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = [:email_conversation_creation]
      notification_setting.selected_push_flags = [:push_conversation_creation]
      notification_setting.save!
    end

    def build_notification(conversation, type: 'conversation_creation')
      described_class.new(
        notification_type: type,
        user: agent,
        account: account,
        primary_actor: conversation
      ).perform
    end

    context 'when the agent has conversation_manage permission' do
      before do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_manage'])
        account_user.update!(custom_role: custom_role)
      end

      it 'creates a notification for any inbox conversation' do
        conversation = create(:conversation, account: account, inbox: inbox)

        expect { build_notification(conversation) }.to change { agent.notifications.count }.by(1)
      end
    end

    context 'when the agent has conversation_unassigned_manage permission' do
      before do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_unassigned_manage'])
        account_user.update!(custom_role: custom_role)
      end

      it 'creates a notification for unassigned conversations' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)

        expect { build_notification(conversation) }.to change { agent.notifications.count }.by(1)
      end

      it 'creates a notification for conversations assigned to the agent' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)

        expect { build_notification(conversation) }.to change { agent.notifications.count }.by(1)
      end

      it 'does not create a notification for conversations assigned to someone else' do
        other_agent = create(:user, account: account, role: :agent)
        create(:inbox_member, user: other_agent, inbox: inbox)
        conversation = create(:conversation, account: account, inbox: inbox, assignee: other_agent)

        expect { build_notification(conversation) }.not_to(change { agent.notifications.count })
      end
    end

    context 'when the agent has conversation_participating_manage permission' do
      before do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
        account_user.update!(custom_role: custom_role)
      end

      it 'creates a notification for conversations assigned to the agent' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)

        expect { build_notification(conversation) }.to change { agent.notifications.count }.by(1)
      end

      it 'creates a notification for conversations the agent participates in' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)
        create(:conversation_participant, conversation: conversation, account: account, user: agent)

        expect { build_notification(conversation) }.to change { agent.notifications.count }.by(1)
      end

      it 'does not create a notification for unassigned conversations the agent does not participate in' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)

        expect { build_notification(conversation) }.not_to(change { agent.notifications.count })
      end
    end

    context 'when the custom role grants no conversation permissions' do
      before do
        custom_role = create(:custom_role, account: account, permissions: ['contact_manage'])
        account_user.update!(custom_role: custom_role)
      end

      it 'does not create a notification' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)

        expect { build_notification(conversation) }.not_to(change { agent.notifications.count })
      end
    end
  end
end
