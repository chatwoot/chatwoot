require 'rails_helper'

RSpec.describe Contacts::CompanyAssociationService, type: :service do
  let(:account) { create(:account) }
  let(:service) { described_class.new }

  describe '#associate_company_from_email' do
    context 'when contact has business email and no company' do
      it 'creates a new company and associates it' do
        contact = create(:contact, email: 'john@acme.com', account: account, company_id: nil)
        Company.delete_all # Delete any companies created by the callback
        # rubocop:disable Rails/SkipsModelValidations
        contact.update_column(:company_id, nil) # Delete the company association created by the callback
        # rubocop:enable Rails/SkipsModelValidations

        valid_email_address = instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false)
        allow(ValidEmail2::Address).to receive(:new).with('john@acme.com').and_return(valid_email_address)
        allow(EmailProviderInfo).to receive(:call).with('john@acme.com').and_return(nil)

        expect do
          service.associate_company_from_email(contact)
        end.to change(Company, :count).by(1)

        contact.reload
        expect(contact.company).to be_present
        expect(contact.company.domain).to eq('acme.com')
        expect(contact.company.name).to eq('Acme')
      end

      it 'reuses existing company with same domain' do
        existing_company = create(:company, domain: 'acme.com', account: account)
        contact = create(:contact, email: 'john@acme.com', account: account, company_id: nil)
        # rubocop:disable Rails/SkipsModelValidations
        contact.update_column(:company_id, nil) # Delete the company association created by the callback
        # rubocop:enable Rails/SkipsModelValidations

        valid_email_address = instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false)
        allow(ValidEmail2::Address).to receive(:new).with('john@acme.com').and_return(valid_email_address)
        allow(EmailProviderInfo).to receive(:call).with('john@acme.com').and_return(nil)

        expect do
          service.associate_company_from_email(contact)
        end.not_to change(Company, :count)

        contact.reload
        expect(contact.company).to eq(existing_company)
      end

      it 'increments company contacts_count when associating contact' do
        # Create contact without email to avoid auto-association
        contact = create(:contact, email: nil, account: account)
        # Manually set email to bypass callbacks
        # rubocop:disable Rails/SkipsModelValidations
        contact.update_column(:email, 'jane@techcorp.com')
        # rubocop:enable Rails/SkipsModelValidations

        valid_email_address = instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false)
        allow(ValidEmail2::Address).to receive(:new).with('jane@techcorp.com').and_return(valid_email_address)
        allow(EmailProviderInfo).to receive(:call).with('jane@techcorp.com').and_return(nil)

        service.associate_company_from_email(contact)

        contact.reload
        expect(contact.company).to be_present
        expect(contact.company.contacts_count).to eq(1)
      end
    end

    context 'when contact already has a company' do
      it 'skips association and returns nil' do
        existing_company = create(:company, account: account)
        contact = create(:contact, email: 'john@acme.com', account: account, company_id: existing_company.id)
        result = service.associate_company_from_email(contact)

        expect(result).to be_nil
        contact.reload
        expect(contact.company).to eq(existing_company)
      end
    end

    context 'when contact has free email provider' do
      it 'skips association for email' do
        contact = create(:contact, email: 'john@gmail.com', account: account, company_id: nil)
        expect do
          service.associate_company_from_email(contact)
        end.not_to change(Company, :count)
        contact.reload
        expect(contact.company).to be_nil
      end
    end

    context 'when contact has no email' do
      it 'skips association' do
        contact = create(:contact, email: nil, account: account, company_id: nil)

        result = service.associate_company_from_email(contact)
        expect(result).to be_nil
        expect(contact.reload.company).to be_nil
      end
    end
  end
end
