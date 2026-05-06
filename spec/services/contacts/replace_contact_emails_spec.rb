# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contacts::ReplaceContactEmails do
  describe '#perform' do
    it 'normalizes, dedupes, mirrors the first email, and preserves ordered emails' do
      contact = create(:contact, email: 'old@example.com')
      create(:contact_email, account: contact.account, contact: contact, email: 'stale@example.com')

      described_class.new(
        contact: contact,
        emails: ['Primary@Example.com', 'zeta@example.com', 'alpha@example.com', 'zeta@example.com']
      ).perform

      expect(contact.reload.email).to eq('primary@example.com')
      expect(contact.contact_emails.order(primary: :desc, id: :asc).pluck(:email, :primary)).to eq(
        [
          ['primary@example.com', true],
          ['zeta@example.com', false],
          ['alpha@example.com', false]
        ]
      )
      expect(contact.all_emails).to eq(['primary@example.com', 'zeta@example.com', 'alpha@example.com'])
    end

    it 'clears all identities and mirrors the legacy email to nil when the replacement list is empty' do
      contact = create(:contact, email: 'primary@example.com')
      create(:contact_email, account: contact.account, contact: contact, email: 'secondary@example.com')

      described_class.new(contact: contact, emails: []).perform

      expect(contact.reload.email).to be_nil
      expect(contact.contact_emails).to be_empty
    end

    it 'promotes the new first email and demotes the old primary during rotation' do
      contact = create(:contact, email: 'old-primary@example.com')
      create(:contact_email, account: contact.account, contact: contact, email: 'secondary@example.com')

      described_class.new(
        contact: contact,
        emails: ['secondary@example.com', 'old-primary@example.com']
      ).perform

      contact.reload

      expect(contact.email).to eq('secondary@example.com')
      expect(contact.contact_emails.find_by!(email: 'secondary@example.com')).to have_attributes(primary: true)
      expect(contact.contact_emails.find_by!(email: 'old-primary@example.com')).to have_attributes(primary: false)
    end

    it 'falls back to the legacy email when the replacement list is blank' do
      contact = create(:contact)

      described_class.new(contact: contact, emails: nil, legacy_email: ' Legacy@Example.com ').perform

      expect(contact.reload.email).to eq('legacy@example.com')
      expect(contact.contact_emails.order(primary: :desc, email: :asc).pluck(:email, :primary)).to eq(
        [
          ['legacy@example.com', true]
        ]
      )
    end
  end
end
