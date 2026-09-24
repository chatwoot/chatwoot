require 'rails_helper'

RSpec.describe Companies::SyncContactNamesJob, type: :job do
  let(:account) { create(:account) }
  let(:company) { create(:company, account: account, name: 'Acme') }

  describe '#perform' do
    it 'updates linked contact company names' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })

      company.update!(name: 'Acme Labs')

      described_class.perform_now(company_id: company.id)

      expect(contact.reload.additional_attributes).to eq('company_name' => 'Acme Labs', 'city' => 'Berlin')
    end

    it 'uses the current company name when a stale rename job runs' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme' })
      company.update!(name: 'Acme Labs')

      described_class.perform_now(company_id: company.id)

      expect(contact.reload.additional_attributes).to eq('company_name' => 'Acme Labs')
    end

    it 'does not save contacts while syncing the denormalized company name' do
      contact = create(:contact, account: account, company: company, additional_attributes: { 'company_name' => 'Acme' })
      original_updated_at = contact.reload.updated_at

      company.update!(name: 'Acme Labs')

      described_class.perform_now(company_id: company.id)

      expect(contact.reload.updated_at).to eq(original_updated_at)
    end
  end
end
