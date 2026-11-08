require 'rails_helper'

RSpec.describe Migration::CompanyAccountBatchJob, type: :job do
  let(:account) { create(:account) }

  describe '#perform' do
    before do
      # Stub EmailProvideInfo to control behavior in tests
      allow(EmailProviderInfo).to receive(:call) do |email|
        domain = email.split('@').last&.downcase
        case domain
        when 'gmail.com', 'yahoo.com', 'hotmail.com', 'uol.com.br'
          'free_provider' # generic free provider name
        end
      end
    end

    context 'when contact has business email' do
      let!(:contact) { create(:contact, account: account, email: 'user@acme.com') }

      it 'creates a company and associates the contact' do
        # Clean up companies created by Part 2's callback
        Company.delete_all
        # rubocop:disable Rails/SkipsModelValidations
        contact.update_column(:company_id, nil)
        # rubocop:enable Rails/SkipsModelValidations

        expect do
          described_class.perform_now(account)
        end.to change(Company, :count).by(1)
        contact.reload
        expect(contact.company).to be_present
        expect(contact.company.domain).to eq('acme.com')
        expect(contact.company.name).to eq('Acme')
      end
    end

    context 'when contact has free email' do
      let!(:contact) { create(:contact, account: account, email: 'user@gmail.com') }

      it 'does not create a company' do
        expect do
          described_class.perform_now(account)
        end.not_to change(Company, :count)
        contact.reload
        expect(contact.company_id).to be_nil
      end
    end

    context 'when contact has company_name in additional_attributes' do
      let!(:contact) do
        create(:contact, account: account, email: 'user@acme.com', additional_attributes: { 'company_name' => 'Acme Corporation' })
      end

      it 'uses the saved company name' do
        described_class.perform_now(account)
        contact.reload
        expect(contact.company.name).to eq('Acme Corporation')
      end
    end

    context 'when contact already has a company' do
      let!(:existing_company) { create(:company, account: account, domain: 'existing.com') }
      let!(:contact) do
        create(:contact, account: account, email: 'user@acme.com', company: existing_company)
      end

      it 'does not change the existing company' do
        described_class.perform_now(account)
        contact.reload
        expect(contact.company_id).to eq(existing_company.id)
      end
    end

    context 'when multiple contacts have the same domain' do
      let!(:contact1) { create(:contact, account: account, email: 'user1@acme.com') }
      let!(:contact2) { create(:contact, account: account, email: 'user2@acme.com') }

      it 'creates only one company for the domain' do
        # Clean up companies created by Part 2's callback
        Company.delete_all
        # rubocop:disable Rails/SkipsModelValidations
        contact1.update_column(:company_id, nil)
        contact2.update_column(:company_id, nil)
        # rubocop:enable Rails/SkipsModelValidations

        expect do
          described_class.perform_now(account)
        end.to change(Company, :count).by(1)
        contact1.reload
        contact2.reload
        expect(contact1.company_id).to eq(contact2.company_id)
        expect(contact1.company.domain).to eq('acme.com')
      end
    end

    context 'when contact has no email' do
      let!(:contact) { create(:contact, account: account, email: nil) }

      it 'skips the contact' do
        expect do
          described_class.perform_now(account)
        end.not_to change(Company, :count)
        contact.reload
        expect(contact.company_id).to be_nil
      end
    end

    context 'when processing large batch' do
      before do
        contacts_data = Array.new(2000) do |i|
          {
            account_id: account.id,
            email: "user#{i}@company#{i % 100}.com",
            name: "User #{i}",
            created_at: Time.current,
            updated_at: Time.current
          }
        end
        # rubocop:disable Rails/SkipsModelValidations
        Contact.insert_all(contacts_data)
        # rubocop:enable Rails/SkipsModelValidations
      end

      it 'processes all contacts in batches' do
        expect do
          described_class.perform_now(account)
        end.to change(Company, :count).by(100)
        expect(account.contacts.where.not(company_id: nil).count).to eq(2000)
      end
    end
  end
end
