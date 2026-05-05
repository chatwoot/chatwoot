# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactEmail do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: 'primary@example.com') }

  describe 'validations' do
    it 'normalizes and validates email' do
      contact_email = build(:contact_email, contact: contact, account: account, email: ' ALIAS@EXAMPLE.COM ')

      expect(contact_email).to be_valid
      expect(contact_email.email).to eq('alias@example.com')
    end

    it 'rejects invalid email addresses' do
      contact_email = build(:contact_email, contact: contact, account: account, email: 'not-an-email')

      expect(contact_email).not_to be_valid
      expect(contact_email.errors[:email]).to be_present
    end

    it 'is unique per account across additional emails' do
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')
      duplicate_contact = create(:contact, account: account, email: 'other@example.com')

      duplicate = build(:contact_email, contact: duplicate_contact, account: account, email: ' ALIAS@EXAMPLE.COM ')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "cannot duplicate another contact's primary email in the same account" do
      other_contact = create(:contact, account: account, email: 'owner@example.com')

      contact_email = build(:contact_email, contact: contact, account: account, email: 'owner@example.com')

      expect(contact_email).not_to be_valid
      expect(contact_email.errors[:email]).to be_present
      expect(contact_email.contact).not_to eq(other_contact)
    end

    it "cannot duplicate its own contact's primary email" do
      contact_email = build(:contact_email, contact: contact, account: account, email: 'primary@example.com')

      expect(contact_email).not_to be_valid
      expect(contact_email.errors[:email]).to be_present
    end

    it 'can use the same email in a different account' do
      create(:contact, account: account, email: 'owner@example.com')
      other_account = create(:account)
      other_contact = create(:contact, account: other_account, email: 'primary@example.com')

      contact_email = build(:contact_email, contact: other_contact, account: other_account, email: 'owner@example.com')

      expect(contact_email).to be_valid
    end

    it 'rejects account/contact mismatches' do
      other_account = create(:account)
      mismatch = build(:contact_email, contact: contact, account: other_account, email: 'alias@example.com')

      expect(mismatch).not_to be_valid
      expect(mismatch.errors[:account]).to be_present
    end
  end
end
