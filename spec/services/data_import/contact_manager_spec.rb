require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:manager) { described_class.new(account) }

  describe '#build_contact' do
    it 'maps CSV company column to additional_attributes company keys' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Imported Co'
      )

      expect(contact.additional_attributes['company_name']).to eq('Imported Co')
      expect(contact.additional_attributes['company']).to eq('Imported Co')
    end

    it 'prefers company_name when both company and company_name are present' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Legacy column',
        company_name: 'Canonical name'
      )

      expect(contact.additional_attributes['company_name']).to eq('Canonical name')
      expect(contact.additional_attributes['company']).to eq('Canonical name')
    end

    it 'does not duplicate company fields into custom_attributes' do
      contact = manager.build_contact(
        email: 'user@example.com',
        company: 'Imported Co',
        custom_field: 'x'
      )

      expect(contact.custom_attributes).to eq({ 'custom_field' => 'x' })
    end

    it 'preserves legitimate company custom attributes on re-import' do
      create(:contact, :with_email, account: account, email: 'legacy@example.com',
                                   custom_attributes: { 'company' => 'Custom company', 'company_name' => 'Custom company name', 'foo' => 'bar' })

      contact = manager.build_contact(
        email: 'legacy@example.com',
        company: 'Acme Inc',
        foo: 'updated'
      )

      expect(contact.additional_attributes['company_name']).to eq('Acme Inc')
      expect(contact.additional_attributes['company']).to eq('Acme Inc')
      expect(contact.custom_attributes['company']).to eq('Custom company')
      expect(contact.custom_attributes['company_name']).to eq('Custom company name')
      expect(contact.custom_attributes['foo']).to eq('updated')
    end
  end
end
