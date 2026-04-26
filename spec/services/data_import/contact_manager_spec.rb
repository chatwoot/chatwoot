require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:contact_manager) { described_class.new(account) }

  describe '#build_contact' do
    context 'when building a contact with company field' do
      let(:params) do
        {
          name: 'John Doe',
          email: 'john@example.com',
          company: 'Acme Corp'
        }
      end

      it 'stores company under company_name key in additional_attributes' do
        contact = contact_manager.build_contact(params)
        expect(contact.additional_attributes['company_name']).to eq('Acme Corp')
      end
    end

    context 'when building a contact with company_name field' do
      let(:params) do
        {
          name: 'Jane Doe',
          email: 'jane@example.com',
          company_name: 'Tech Inc'
        }
      end

      it 'stores company_name under company_name key in additional_attributes' do
        contact = contact_manager.build_contact(params)
        expect(contact.additional_attributes['company_name']).to eq('Tech Inc')
      end
    end

    context 'when building a contact with both company and company_name fields' do
      let(:params) do
        {
          name: 'Bob Smith',
          email: 'bob@example.com',
          company: 'Old Company',
          company_name: 'New Company'
        }
      end

      it 'prioritizes company_name over company' do
        contact = contact_manager.build_contact(params)
        expect(contact.additional_attributes['company_name']).to eq('New Company')
      end
    end
  end

  describe '#find_existing_contact' do
    let!(:existing_contact) { create(:contact, account: account, email: 'existing@example.com') }

    context 'when updating existing contact with company field' do
      let(:params) do
        {
          email: 'existing@example.com',
          company: 'Updated Company'
        }
      end

      it 'stores company under company_name key in additional_attributes' do
        contact = contact_manager.find_existing_contact(params)
        expect(contact.additional_attributes['company_name']).to eq('Updated Company')
      end
    end
  end
end