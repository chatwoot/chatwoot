# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contacts::EmailAddressesSyncService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: nil) }

  describe '#perform' do
    it 'stores aliases and mirrors the primary email on contacts.email' do
      described_class.new(
        contact: contact,
        email_addresses: [
          { email: 'bob@gmail.com', primary: true },
          { email: 'bo@myworkplace.com', primary: false }
        ]
      ).perform

      expect(contact.reload.email).to eq('bob@gmail.com')
      expect(contact.contact_emails.pluck(:email, :primary)).to contain_exactly(
        ['bo@myworkplace.com', false],
        ['bob@gmail.com', true]
      )
    end

    it 'rejects duplicate normalized rows and multiple primaries' do
      expect do
        described_class.new(
          contact: contact,
          email_addresses: [
            { email: 'Bob@gmail.com ', primary: true },
            { email: ' bob@gmail.com', primary: false }
          ]
        ).perform
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect do
        described_class.new(
          contact: contact,
          email_addresses: [
            { email: 'one@example.com', primary: true },
            { email: 'two@example.com', primary: true }
          ]
        ).perform
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'promotes an existing alias or auto-promotes the oldest alias on legacy writes' do
      described_class.new(
        contact: contact,
        email_addresses: [
          { email: 'old-primary@example.com', primary: true },
          { email: 'alias@example.com', primary: false }
        ]
      ).perform

      expect do
        described_class.new(contact: contact, email: 'alias@example.com').perform
      end.not_to change { contact.reload.contact_emails.count }

      expect(contact.reload.email).to eq('alias@example.com')
      expect(contact.contact_emails.order(:email).pluck(:email, :primary)).to eq([
                                                                                   ['alias@example.com', true],
                                                                                   ['old-primary@example.com', false]
                                                                                 ])

      described_class.new(contact: contact, email: nil).perform

      expect(contact.reload.email).to eq('old-primary@example.com')
      expect(contact.contact_emails.pluck(:email, :primary)).to contain_exactly(
        ['old-primary@example.com', true]
      )
    end
  end
end
