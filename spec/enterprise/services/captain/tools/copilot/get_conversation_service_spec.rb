require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetConversationService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('get_conversation')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Get details of a conversation including messages and contact information')
    end
  end

  describe '#parameters' do
    it 'defines conversation_id parameter' do
      expect(service.parameters.keys).to contain_exactly(:conversation_id)
    end
  end

  describe '#active?' do
    context 'when user is an admin' do
      let(:user) { create(:user, :administrator, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role with conversation_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_manage']) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role with conversation_unassigned_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_unassigned_manage']) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role with conversation_participating_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role without any conversation permissions' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: []) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns false' do
        expect(service.active?).to be false
      end
    end
  end

  describe '#execute' do
    context 'when conversation is not found' do
      it 'returns not found message' do
        expect(service.execute(conversation_id: 999)).to eq('Conversation not found')
      end
    end

    context 'when conversation exists' do
      let(:inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before { create(:inbox_member, user: user, inbox: inbox) }

      it 'returns the conversation in llm text format' do
        result = service.execute(conversation_id: conversation.display_id)
        expect(result).to eq(conversation.to_llm_text)
      end

      it 'includes private messages in the llm text format' do
        # Create a regular message
        create(:message,
               conversation: conversation,
               message_type: 'outgoing',
               content: 'Regular message',
               private: false)

        # Create a private message
        create(:message,
               conversation: conversation,
               message_type: 'outgoing',
               content: 'Private note content',
               private: true)

        result = service.execute(conversation_id: conversation.display_id)

        # Verify that the result includes both regular and private messages
        expect(result).to include('Regular message')
        expect(result).to include('Private note content')
        expect(result).to include('[Private Note]')
      end

      context 'when conversation belongs to different account' do
        let(:other_account) { create(:account) }
        let(:other_inbox) { create(:inbox, account: other_account) }
        let(:other_conversation) { create(:conversation, account: other_account, inbox: other_inbox) }

        it 'returns not found message' do
          expect(service.execute(conversation_id: other_conversation.display_id)).to eq('Conversation not found')
        end
      end
    end

    context 'when conversation is in an inbox the user does not belong to' do
      let(:other_inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: other_inbox) }

      it 'returns not found message' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq('Conversation not found')
      end

      context 'when user is an administrator' do
        let(:user) { create(:user, :administrator, account: account) }

        it 'returns the conversation in llm text format' do
          expect(service.execute(conversation_id: conversation.display_id)).to eq(conversation.to_llm_text)
        end
      end
    end

    context 'when conversation is accessible through team membership' do
      let(:team) { create(:team, account: account) }
      let(:conversation) { create(:conversation, :with_team, account: account, team: team) }

      before { create(:team_member, team: team, user: user) }

      it 'returns the conversation in llm text format' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq(conversation.to_llm_text)
      end
    end

    context 'when user only has conversation_participating_manage permission' do
      let(:inbox) { create(:inbox, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:inbox_member, user: user, inbox: inbox)
        AccountUser.find_by(user: user, account: account).update(role: :agent, custom_role: custom_role)
      end

      it 'returns not found message for a conversation they neither own nor participate in' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq('Conversation not found')
      end

      it 'returns the conversation when it is assigned to them' do
        conversation.update(assignee: user)
        expect(service.execute(conversation_id: conversation.display_id)).to eq(conversation.to_llm_text)
      end
    end

    context 'when user only has conversation_unassigned_manage permission' do
      let(:inbox) { create(:inbox, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_unassigned_manage']) }
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, ai_assignee: agent_bot) }

      before do
        create(:inbox_member, user: user, inbox: inbox)
        AccountUser.find_by!(user: user, account: account).update!(role: :agent, custom_role: custom_role)
        create(:message, conversation: conversation, private: true, content: 'Agent bot private note')
      end

      it 'does not return a conversation assigned to an agent bot' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq('Conversation not found')
      end
    end

    context 'when an administrator has a limited custom role' do
      let(:user) { create(:user, :administrator, account: account) }
      let(:inbox) { create(:inbox, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:inbox_member, user: user, inbox: inbox)
        AccountUser.find_by(user: user, account: account).update!(custom_role: custom_role)
        create(:message, conversation: conversation, private: true, content: 'Restricted private note')
      end

      it 'does not return an unrelated conversation or its private messages' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq('Conversation not found')
      end

      it 'returns a conversation assigned to the user outside their inboxes' do
        assigned_conversation = create(:conversation, account: account, assignee: user)

        expect(service.execute(conversation_id: assigned_conversation.display_id)).to eq(assigned_conversation.to_llm_text)
      end
    end

    context 'when an administrator has a conversation_manage custom role' do
      let(:user) { create(:user, :administrator, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_manage']) }
      let(:conversation) { create(:conversation, account: account) }

      before { AccountUser.find_by(user: user, account: account).update!(custom_role: custom_role) }

      it 'returns a conversation outside their inboxes' do
        expect(service.execute(conversation_id: conversation.display_id)).to eq(conversation.to_llm_text)
      end
    end
  end
end
