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

    it 'clears company names for provided contacts' do
      contact = create(:contact, account: account, company: nil, additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })

      described_class.perform_now(contact_ids: [contact.id])

      expect(contact.reload.additional_attributes).to eq('city' => 'Berlin')
    end

    it 'keeps reassigned contact company names during delete cleanup' do
      other_company = create(:company, account: account, name: 'Other Company')
      contact = create(:contact, account: account, company: other_company, additional_attributes: { 'company_name' => 'Other Company' })

      described_class.perform_now(contact_ids: [contact.id])

      expect(contact.reload.additional_attributes).to eq('company_name' => 'Other Company')
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
