# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db/migrate/20260412120000_create_contact_emails')

RSpec.describe CreateContactEmails do
  describe '#backfill_contact_emails' do
    it 'keeps a normalized legacy email with the contact that already owns it exactly' do
      account = create(:account)
      older_mixed_case_contact = create(:contact, account: account, email: nil, created_at: 2.days.ago)
      lowercase_contact = create(:contact, account: account, email: nil, created_at: 1.day.ago)

      # The migration must handle legacy rows created before current normalization.
      # rubocop:disable Rails/SkipsModelValidations
      older_mixed_case_contact.update_columns(email: 'User@example.com')
      lowercase_contact.update_columns(email: 'user@example.com')
      # rubocop:enable Rails/SkipsModelValidations

      ContactEmail.where(account: account).delete_all

      described_class.new.send(:backfill_contact_emails)

      expect(ContactEmail.find_by!(account: account, email: 'user@example.com').contact).to eq(lowercase_contact)
    end
  end
end
