require 'rails_helper'

RSpec.describe Companies::ContactMembershipService, type: :service do
  let(:account) { create(:account) }

  it 'uses current company counts when a CSV import reassigns the contact before the dashboard saves', :aggregate_failures do
    account.enable_features!(:companies)
    previous, imported, target = create_list(:company, 3, account: account)
    contact = create(:contact, account: account, company: previous, identifier: 'customer-1')

    Contact.transaction do
      DataImports::Csv::ContactWriter.new(account).perform('identifier' => contact.identifier, 'company_name' => imported.name)
    end
    described_class.new(company: target).assign(contact: contact)

    expect(contact.reload.company).to eq(target)
    expect([previous, imported, target].map { |company| company.reload.contacts_count }).to eq([0, 0, 1])
  end

  it 'keeps the new membership if a contact was moved before unlinking' do
    previous, current = create_list(:company, 2, account: account)
    contact = create(:contact, account: account, company: previous)
    Contact.find(contact.id).update!(company: current)

    described_class.new(company: previous).remove(contact: contact)

    expect(contact.reload.company).to eq(current)
  end
end
