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
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            conversation_id: {
              type: 'number',
              description: 'The ID of the conversation to retrieve'
            }
          },
          required: %w[conversation_id]
        }
      )
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
    context 'when conversation_id is blank' do
      it 'returns error message' do
        expect(service.execute({})).to eq('Missing required parameters')
      end
    end

    context 'when conversation is not found' do
      it 'returns not found message' do
        expect(service.execute({ 'conversation_id' => 999 })).to eq('Conversation not found')
      end
    end

    context 'when conversation exists' do
      let(:inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      it 'returns the conversation in llm text format' do
        result = service.execute({ 'conversation_id' => conversation.display_id })
        expect(result).to eq(conversation.to_llm_text)
      end

      context 'when conversation belongs to different account' do
        let(:other_account) { create(:account) }
        let(:other_inbox) { create(:inbox, account: other_account) }
        let(:other_conversation) { create(:conversation, account: other_account, inbox: other_inbox) }

        it 'returns not found message' do
          expect(service.execute({ 'conversation_id' => other_conversation.display_id })).to eq('Conversation not found')
        end
      end
    end
  end
end
