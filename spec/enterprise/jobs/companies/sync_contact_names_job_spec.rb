require 'rails_helper'

RSpec.describe Companies::SyncContactNamesJob, type: :job do
  let(:account) { create(:account) }
  let(:company) { create(:company, account: account, name: 'Acme') }

  describe '#perform' do
    def cleanup_attributes(company_id, company_name)
      {
        'company_name' => company_name,
        '_company_name_cleanup' => { 'company_id' => company_id, 'company_name' => company_name }
      }
    end

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
      contact = create(
        :contact,
        account: account,
        company: nil,
        additional_attributes: cleanup_attributes(company.id, 'Acme').merge('city' => 'Berlin')
      )

      described_class.perform_now(cleanup_company_id: company.id, cleanup_account_id: account.id)

      expect(contact.reload.additional_attributes).to eq('city' => 'Berlin')
    end

    it 'keeps unrelated unassigned contact company names during delete cleanup' do
      contact = create(:contact, account: account, company: nil, additional_attributes: { 'company_name' => 'Acme' })

      described_class.perform_now(cleanup_company_id: company.id, cleanup_account_id: account.id)

      expect(contact.reload.additional_attributes).to eq('company_name' => 'Acme')
    end

    it 'keeps marked contacts in other accounts during delete cleanup' do
      other_account = create(:account)
      contact = create(
        :contact,
        account: other_account,
        company: nil,
        additional_attributes: cleanup_attributes(company.id, 'Acme')
      )

      described_class.perform_now(cleanup_company_id: company.id, cleanup_account_id: account.id)

      expect(contact.reload.additional_attributes).to eq(cleanup_attributes(company.id, 'Acme'))
    end

    it 'keeps newer manual company names during delete cleanup' do
      contact = create(
        :contact,
        account: account,
        company: nil,
        additional_attributes: {
          'company_name' => 'New Company',
          '_company_name_cleanup' => { 'company_id' => company.id, 'company_name' => 'Acme' }
        }
      )

      described_class.perform_now(cleanup_company_id: company.id, cleanup_account_id: account.id)

      expect(contact.reload.additional_attributes).to eq('company_name' => 'New Company')
    end

    it 'keeps reassigned contact company names during delete cleanup' do
      other_company = create(:company, account: account, name: 'Other Company')
      contact = create(:contact, account: account, company: other_company, additional_attributes: cleanup_attributes(company.id, 'Other Company'))

      described_class.perform_now(cleanup_company_id: company.id, cleanup_account_id: account.id)

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
