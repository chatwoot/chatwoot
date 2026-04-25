require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:manager) { described_class.new(account) }

  describe '#build_contact' do
    context 'when params include a company' do
      let(:params) do
        {
          name: 'Jane Doe',
          email: 'jane@example.com',
          company: 'Acme Corp'
        }
      end

      it 'stores company under company_name key so the app can sort and display it' do
        contact = manager.build_contact(params)
        contact.save!

        expect(contact.additional_attributes['company_name']).to eq('Acme Corp')
      end

      it 'does not store company under the legacy company key' do
        contact = manager.build_contact(params)
        contact.save!

        expect(contact.additional_attributes['company']).to be_nil
      end
    end
  end

  describe '#find_or_initialize_contact (existing contact update)' do
    context 'when updating an existing contact with a company' do
      let!(:existing_contact) { create(:contact, account: account, email: 'jane@example.com') }
      let(:params) do
        {
          email: 'jane@example.com',
          company: 'Updated Corp'
        }
      end

      it 'stores company_name so the contact can be sorted by company' do
        manager.find_existing_contact(params)
        existing_contact.reload

        expect(existing_contact.additional_attributes['company_name']).to eq('Updated Corp')
      end
    end
  end
end
