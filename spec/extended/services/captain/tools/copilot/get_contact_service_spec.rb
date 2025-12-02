require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetContactService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('get_contact')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Get details of a contact including their profile information')
    end
  end

  describe '#parameters' do
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            contact_id: {
              type: 'number',
              description: 'The ID of the contact to retrieve'
            }
          },
          required: %w[contact_id]
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

    context 'when user has custom role with contact_manage permission' do
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

    context 'when user has custom role without contact_manage permission' do
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
    context 'when contact_id is blank' do
      it 'returns error message' do
        expect(service.execute({})).to eq('Missing required parameters')
      end
    end

    context 'when contact is not found' do
      it 'returns not found message' do
        expect(service.execute({ 'contact_id' => 999 })).to eq('Contact not found')
      end
    end

    context 'when contact exists' do
      let(:contact) { create(:contact, account: account) }

      it 'returns the contact in llm text format' do
        result = service.execute({ 'contact_id' => contact.id })
        expect(result).to eq(contact.to_llm_text)
      end

      context 'when contact belongs to different account' do
        let(:other_account) { create(:account) }
        let(:other_contact) { create(:contact, account: other_account) }

        it 'returns not found message' do
          expect(service.execute({ 'contact_id' => other_contact.id })).to eq('Contact not found')
        end
      end
    end
  end
end
