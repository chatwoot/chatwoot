require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:manager) { described_class.new(account) }

  describe '#build_contact' do
    it 'maps CSV company column to additional_attributes company_name' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Imported Co'
      )

      expect(contact.additional_attributes['company_name']).to eq('Imported Co')
      expect(contact.additional_attributes['company']).to be_nil
    end

    it 'prefers company_name when both company and company_name are present' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Legacy column',
        company_name: 'Canonical name'
      )

      expect(contact.additional_attributes['company_name']).to eq('Canonical name')
    end

    it 'does not duplicate company fields into custom_attributes' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Imported Co',
        custom_field: 'x'
      )

      expect(contact.custom_attributes).to eq({ 'custom_field' => 'x' })
    end

    it 'removes legacy company keys from existing custom_attributes on re-import' do
      create(:contact, :with_email, account: account, email: 'legacy@example.com',
                                   custom_attributes: { 'company' => 'Stale', 'company_name' => 'Also stale', 'foo' => 'bar' })

      contact = manager.build_contact(
        email: 'legacy@example.com',
        company: 'Acme Inc',
        foo: 'updated'
      )

      expect(contact.additional_attributes['company_name']).to eq('Acme Inc')
      expect(contact.custom_attributes.keys).not_to include('company', 'company_name')
      expect(contact.custom_attributes['foo']).to eq('updated')
    end
  end
end
