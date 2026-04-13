# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactEmail do
  describe 'validations' do
    it 'normalizes email and enforces account-scoped uniqueness case insensitively' do
      existing = create(:contact_email, email: 'Secondary@Example.com')
      duplicate = build(:contact_email, account: existing.account, email: 'secondary@example.com')

      expect(existing.email).to eq('secondary@example.com')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
    end

    it 'allows only one primary email per contact' do
      contact = create(:contact, email: 'primary@example.com')

      duplicate_primary = build(
        :contact_email,
        account: contact.account,
        contact: contact,
        email: 'secondary@example.com',
        primary: true
      )

      expect(duplicate_primary).not_to be_valid
      expect(duplicate_primary.errors[:primary]).to include('has already been taken')
    end

    it "does not allow claiming another contact's legacy email when no alias row exists yet" do
      account = create(:account)
      legacy_owner = create(:contact, account: account)
      legacy_owner.update_columns(email: 'legacy-only@example.com', updated_at: Time.current)
      claiming_contact = create(:contact, account: account, email: 'other@example.com')

      conflicting_alias = build(
        :contact_email,
        account: account,
        contact: claiming_contact,
        email: 'legacy-only@example.com'
      )

      expect(conflicting_alias).not_to be_valid
      expect(conflicting_alias.errors[:email]).to include('has already been taken')
    end
  end
end
