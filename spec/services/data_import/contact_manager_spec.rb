require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  subject(:manager) { described_class.new(account) }

  let(:account) { create(:account) }

  describe '#build_contact' do
    context 'when importing a contact with company_name' do
      it 'saves company_name to additional_attributes[:company_name]' do
        params = { name: 'John Doe', email: 'john@example.com', company_name: 'Acme Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to eq('Acme Corp')
      end

      it 'does not save to the incorrect :company key' do
        params = { name: 'John Doe', email: 'john@example.com', company_name: 'Acme Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company]).to be_nil
      end
    end

    context 'when importing a contact without company_name' do
      it 'does not set company_name in additional_attributes' do
        params = { name: 'John Doe', email: 'john@example.com' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to be_nil
      end
    end

    context 'when importing a contact with legacy :company field' do
      it 'saves it to additional_attributes[:company_name] for backwards compatibility' do
        params = { name: 'Jane Doe', email: 'jane@example.com', company: 'Legacy Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to eq('Legacy Corp')
      end
    end
  end
end
