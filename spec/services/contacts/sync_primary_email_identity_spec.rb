# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contacts::SyncPrimaryEmailIdentity do
  describe '#perform' do
    it 'creates or updates the primary contact email from the legacy contact email field' do
      contact = create(:contact)
      create(:contact_email, account: contact.account, contact: contact, email: 'old-primary@example.com', primary: true)
      create(:contact_email, account: contact.account, contact: contact, email: 'secondary@example.com')
      contact.update_column(:email, 'legacy@example.com')

      described_class.new(contact: contact).perform

      expect(contact.reload.contact_emails.order(primary: :desc, email: :asc).pluck(:email, :primary)).to eq([
                                                                                                                 ['legacy@example.com', true],
                                                                                                                 ['old-primary@example.com', false],
                                                                                                                 ['secondary@example.com', false]
                                                                                                               ])
    end

    it 'removes all contact email identities when the legacy contact email field is blank' do
      contact = create(:contact, email: 'primary@example.com')
      create(:contact_email, account: contact.account, contact: contact, email: 'secondary@example.com')
      contact.update_column(:email, nil)

      described_class.new(contact: contact).perform

      expect(contact.reload.email).to be_nil
      expect(contact.contact_emails).to be_empty
    end
  end
end
