require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'company auto-association' do
    let(:account) { create(:account) }

    context 'when creating a new contact with business email' do
      it 'automatically creates and associates a company' do
        expect do
          create(:contact, email: 'john@acme.com', account: account)
        end.to change(Company, :count).by(1)
        contact = described_class.last
        expect(contact.company).to be_present
        expect(contact.company.domain).to eq('acme.com')
      end

      it 'does not create company for free email providers' do
        expect do
          create(:contact, email: 'john@gmail.com', account: account)
        end.not_to change(Company, :count)
      end
    end

    context 'when updating a contact to add email for first time' do
      it 'creates and associates company' do
        contact = create(:contact, email: nil, account: account)
        expect do
          contact.update(email: 'john@acme.com')
        end.to change(Company, :count).by(1)
        contact.reload
        expect(contact.company.domain).to eq('acme.com')
      end
    end

    context 'when updating a contact that already has a company' do
      it 'does not change company when email changes' do
        existing_company = create(:company, domain: 'oldcompany.com', account: account)
        contact = create(:contact, email: 'john@oldcompany.com', company: existing_company, account: account)

        expect do
          contact.update(email: 'john@new_company.com')
        end.not_to change(Company, :count)
        contact.reload
        expect(contact.company).to eq(existing_company)
      end
    end

    context 'when multiple contacts share the same domain' do
      it 'associates all contacts with the same company' do
        contacts = ['john@acme.com', 'jane@acme.com', 'bob@acme.com']
        contacts.each do |contact|
          create(:contact, email: contact, account: account)
        end

        expect(Company.where(domain: 'acme.com', account: account).count).to eq(1)
        company = Company.find_by(domain: 'acme.com', account: account)
        expect(company.contacts.count).to eq(contacts.length)
      end
    end
  end
end
