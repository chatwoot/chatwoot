# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact, '.from_email' do
  let(:account) { create(:account) }

  it 'finds a contact through a non-primary alias' do
    contact = create(:contact, account: account, email: 'bob@gmail.com')
    create(:contact_email, contact: contact, account: account, email: 'bo@myworkplace.com')

    expect(account.contacts.from_email('bo@myworkplace.com')).to eq(contact)
  end

  it 'finds a contact through the primary email' do
    contact = create(:contact, account: account, email: 'legacy@example.com')

    expect(account.contacts.from_email('legacy@example.com')).to eq(contact)
  end
end
