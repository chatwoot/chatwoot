require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchConversationsService do
  let(:account) { create(:account) }
  let(:user) { create(:user, role: 'administrator', account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_conversations')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Search conversations based on parameters')
    end
  end

  describe '#parameters' do
    it 'returns the correct parameter schema' do
      params = service.parameters
      expect(params[:type]).to eq('object')
      expect(params[:properties]).to include(:contact_id, :status, :priority)
    end
  end

  describe '#active?' do
    context 'when user has conversation_manage permission' do
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_manage']) }
      let(:user) { create(:user, account: account) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has conversation_unassigned_manage permission' do
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_unassigned_manage']) }
      let(:user) { create(:user, account: account) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has conversation_participating_manage permission' do
      let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
      let(:user) { create(:user, account: account) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has no relevant conversation permissions' do
      let(:custom_role) { create(:custom_role, account: account, permissions: []) }
      let(:user) { create(:user, account: account) }

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
    let(:contact) { create(:contact, account: account) }
    let!(:open_conversation) { create(:conversation, account: account, contact: contact, status: 'open', priority: 'high') }
    let!(:resolved_conversation) { create(:conversation, account: account, status: 'resolved', priority: 'low') }

    it 'returns all conversations when no filters are applied' do
      result = service.execute({})
      expect(result).to include('Total number of conversations: 2')
      expect(result).to include(open_conversation.to_llm_text(include_contact_details: true))
      expect(result).to include(resolved_conversation.to_llm_text(include_contact_details: true))
    end

    it 'filters conversations by status' do
      result = service.execute({ 'status' => 'open' })
      expect(result).to include('Total number of conversations: 1')
      expect(result).to include(open_conversation.to_llm_text(include_contact_details: true))
      expect(result).not_to include(resolved_conversation.to_llm_text(include_contact_details: true))
    end

    it 'filters conversations by contact_id' do
      result = service.execute({ 'contact_id' => contact.id })
      expect(result).to include('Total number of conversations: 1')
      expect(result).to include(open_conversation.to_llm_text(include_contact_details: true))
      expect(result).not_to include(resolved_conversation.to_llm_text(include_contact_details: true))
    end

    it 'filters conversations by priority' do
      result = service.execute({ 'priority' => 'high' })
      expect(result).to include('Total number of conversations: 1')
      expect(result).to include(open_conversation.to_llm_text(include_contact_details: true))
      expect(result).not_to include(resolved_conversation.to_llm_text(include_contact_details: true))
    end

    it 'returns appropriate message when no conversations are found' do
      result = service.execute({ 'status' => 'snoozed' })
      expect(result).to eq('No conversations found')
    end
  end
end
