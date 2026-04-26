require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  subject(:manager) { described_class.new(account) }

  let(:account) { create(:account) }

  describe '#build_contact' do
    context 'when importing a contact with company_name' do
      it 'saves to additional_attributes[:company_name]' do
        params = { name: 'John Doe', email: 'john@example.com', company_name: 'Acme Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to eq('Acme Corp')
      end

      it 'also backfills additional_attributes[:company] for filter compatibility' do
        params = { name: 'John Doe', email: 'john@example.com', company_name: 'Acme Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company]).to eq('Acme Corp')
      end
    end

    context 'when importing a contact with legacy :company field' do
      it 'saves to additional_attributes[:company_name] for UI compatibility' do
        params = { name: 'Jane Doe', email: 'jane@example.com', company: 'Legacy Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to eq('Legacy Corp')
      end

      it 'also preserves additional_attributes[:company] for filter compatibility' do
        params = { name: 'Jane Doe', email: 'jane@example.com', company: 'Legacy Corp' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company]).to eq('Legacy Corp')
      end
    end

    context 'when importing a contact without company field' do
      it 'does not set company_name in additional_attributes' do
        params = { name: 'John Doe', email: 'john@example.com' }
        contact = manager.build_contact(params)
        expect(contact.additional_attributes[:company_name]).to be_nil
        expect(contact.additional_attributes[:company]).to be_nil
      end
    end
  end
end
