# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactPhone do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, phone_number: '+15551234567') }

  describe 'validations' do
    it 'normalizes and validates phone number' do
      contact_phone = build(:contact_phone, contact: contact, account: account, phone_number: ' +15557654321 ')

      expect(contact_phone).to be_valid
      expect(contact_phone.phone_number).to eq('+15557654321')
    end

    it 'validates E.164 format' do
      contact_phone = build(:contact_phone, contact: contact, account: account, phone_number: '5557654321')

      expect(contact_phone).not_to be_valid
      expect(contact_phone.errors[:phone_number]).to be_present
    end

    it 'is unique per account across additional phones' do
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')
      duplicate_contact = create(:contact, account: account, phone_number: '+15559876543')

      duplicate = build(:contact_phone, contact: duplicate_contact, account: account, phone_number: '+15557654321')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone_number]).to be_present
    end

    it "cannot duplicate another contact's primary phone in the same account" do
      other_contact = create(:contact, account: account, phone_number: '+15557654321')

      contact_phone = build(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      expect(contact_phone).not_to be_valid
      expect(contact_phone.errors[:phone_number]).to be_present
      expect(contact_phone.contact).not_to eq(other_contact)
    end

    it "cannot duplicate its own contact's primary phone" do
      contact_phone = build(:contact_phone, contact: contact, account: account, phone_number: '+15551234567')

      expect(contact_phone).not_to be_valid
      expect(contact_phone.errors[:phone_number]).to be_present
    end

    it 'can use the same phone in a different account' do
      create(:contact, account: account, phone_number: '+15557654321')
      other_account = create(:account)
      other_contact = create(:contact, account: other_account, phone_number: '+15551234567')

      contact_phone = build(:contact_phone, contact: other_contact, account: other_account, phone_number: '+15557654321')

      expect(contact_phone).to be_valid
    end

    it 'rejects account/contact mismatches' do
      other_account = create(:account)
      mismatch = build(:contact_phone, contact: contact, account: other_account, phone_number: '+15557654321')

      expect(mismatch).not_to be_valid
      expect(mismatch.errors[:account]).to be_present
    end
  end
end
