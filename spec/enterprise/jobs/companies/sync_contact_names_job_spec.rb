require 'rails_helper'

RSpec.describe Companies::SyncContactNamesJob, type: :job do
  let(:account) { create(:account) }
  let(:company) { create(:company, account: account, name: 'Acme') }

  describe '#perform' do
    it 'updates linked contact company names' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })

      described_class.perform_now(company_id: company.id, company_name: 'Acme Labs')

      expect(contact.reload.additional_attributes).to eq('company_name' => 'Acme Labs', 'city' => 'Berlin')
    end

    it 'clears company names for provided contacts' do
      contact = create(:contact, account: account, company: nil, additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })

      described_class.perform_now(contact_ids: [contact.id])

      expect(contact.reload.additional_attributes).to eq('city' => 'Berlin')
    end

    it 'does not save contacts while syncing the denormalized company name' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme' })
      original_updated_at = contact.updated_at

      described_class.perform_now(company_id: company.id, company_name: 'Acme Labs')

      expect(contact.reload.updated_at).to eq(original_updated_at)
    end
  end
end
