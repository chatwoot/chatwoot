require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  describe '#update_contact_attributes' do
  context 'when CSV row uses the legacy "company" column name' do
    let(:params) { { name: 'Alice', company: 'Acme Corp' } }

    it 'stores the value under company_name in additional_attributes' do
      manager = described_class.new(account: account, params: params)
      manager.perform
      contact = account.contacts.find_by(name: 'Alice')
      expect(contact.additional_attributes['company_name']).to eq('Acme Corp')
    end

    it 'does not store a stray "company" key' do
      manager = described_class.new(account: account, params: params)
      manager.perform
      contact = account.contacts.find_by(name: 'Alice')
      expect(contact.additional_attributes['company']).to be_nil
    end
  end

  context 'when CSV row uses the canonical "company_name" column name' do
    let(:params) { { name: 'Bob', company_name: 'Beta Ltd' } }

    it 'stores the value under company_name in additional_attributes' do
      manager = described_class.new(account: account, params: params)
      manager.perform
      contact = account.contacts.find_by(name: 'Bob')
      expect(contact.additional_attributes['company_name']).to eq('Beta Ltd')
    end
  end

  context 'when both "company" and "company_name" are present in params' do
    let(:params) { { name: 'Carol', company: 'Old Name', company_name: 'New Name' } }

    it 'prefers company_name over company' do
      manager = described_class.new(account: account, params: params)
      manager.perform
      contact = account.contacts.find_by(name: 'Carol')
      expect(contact.additional_attributes['company_name']).to eq('New Name')
    end
  end
 end
end