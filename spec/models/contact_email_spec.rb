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
  end
end
