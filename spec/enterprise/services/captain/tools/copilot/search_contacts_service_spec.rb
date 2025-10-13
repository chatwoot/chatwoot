require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchContactsService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_contacts')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Search contacts based on query parameters')
    end
  end

  describe '#parameters' do
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            email: {
              type: 'string',
              description: 'Filter contacts by email'
            },
            phone_number: {
              type: 'string',
              description: 'Filter contacts by phone number'
            },
            name: {
              type: 'string',
              description: 'Filter contacts by name (partial match)'
            }
          },
          required: []
        }
      )
    end
  end

  describe '#active?' do
    context 'when user has contact_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['contact_manage']) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user does not have contact_manage permission' do
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
    context 'when contacts are found' do
      let(:contact1) { create(:contact, account: account, email: 'test1@example.com', name: 'Test Contact 1', phone_number: '+1234567890') }
      let(:contact2) { create(:contact, account: account, email: 'test2@example.com', name: 'Test Contact 2', phone_number: '+1234567891') }

      before do
        contact1
        contact2
      end

      it 'returns contacts when filtered by email' do
        result = service.execute({ 'email' => 'test1@example.com' })
        expect(result).to include(contact1.to_llm_text)
        expect(result).not_to include(contact2.to_llm_text)
      end

      it 'returns contacts when filtered by phone number' do
        result = service.execute({ 'phone_number' => '+1234567890' })
        expect(result).to include(contact1.to_llm_text)
        expect(result).not_to include(contact2.to_llm_text)
      end

      it 'returns contacts when filtered by name' do
        result = service.execute({ 'name' => 'Contact 1' })
        expect(result).to include(contact1.to_llm_text)
        expect(result).not_to include(contact2.to_llm_text)
      end

      it 'returns all matching contacts when no filters are provided' do
        result = service.execute({})
        expect(result).to include(contact1.to_llm_text)
        expect(result).to include(contact2.to_llm_text)
      end
    end
  end
end
