# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact, '.from_email' do
  let(:account) { create(:account) }

  it 'finds a contact through a non-primary alias' do
    contact = create(:contact, account: account, email: nil)
    create(:contact_email, contact: contact, account: account, email: 'bob@gmail.com', primary: true)
    create(:contact_email, contact: contact, account: account, email: 'bo@myworkplace.com', primary: false)

    expect(account.contacts.from_email('bo@myworkplace.com')).to eq(contact)
  end

  it 'falls back to contacts.email when child rows are missing during rollout' do
    contact = create(:contact, account: account, email: 'legacy@example.com')
    contact.contact_emails.delete_all

    expect(account.contacts.from_email('legacy@example.com')).to eq(contact)
  end
end
