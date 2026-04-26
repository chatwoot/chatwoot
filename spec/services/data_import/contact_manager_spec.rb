require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) } # Assuming you have FactoryBot set up
  let(:manager) { described_class.new(account) }

  describe '#build_contact' do
    it 'correctly maps the company field to additional_attributes' do
      params = { 'name' => 'John Doe', 'company' => 'ACME Corp' }

      contact = manager.build_contact(params)
      contact.save!

      expect(contact.reload.additional_attributes['company_name']).to eq('ACME Corp')
    end
  end
end
