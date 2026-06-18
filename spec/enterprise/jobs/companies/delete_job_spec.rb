require 'rails_helper'

RSpec.describe Companies::DeleteJob, type: :job do
  let(:account) { create(:account) }
  let(:company) { create(:company, account: account, name: 'Acme') }

  describe '#perform' do
    it 'unlinks contacts, clears denormalized company names, and deletes the company' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })
      other_contact = create(:contact, account: account, additional_attributes: { 'company_name' => 'Acme' })

      described_class.perform_now(company.id)

      expect { company.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(contact.reload.company_id).to be_nil
      expect(contact.additional_attributes).to eq('city' => 'Berlin')
      expect(other_contact.reload.additional_attributes).to eq('company_name' => 'Acme')
    end
  end
end
