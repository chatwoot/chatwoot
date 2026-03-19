# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactEmail do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: nil) }

  describe 'validations' do
    it 'normalizes email and validates uniqueness per account' do
      create(:contact_email, contact: contact, account: account, email: 'bob@gmail.com', primary: true)
      duplicate_contact = create(:contact, account: account, email: nil)

      duplicate = build(:contact_email, contact: duplicate_contact, account: account, email: ' BOB@GMAIL.COM ', primary: false)

      expect(duplicate).not_to be_valid
      expect(duplicate.email).to eq('bob@gmail.com')
      expect(duplicate.errors[:email]).to be_present
    end

    it 'rejects account/contact mismatches' do
      other_account = create(:account)
      mismatch = build(:contact_email, contact: contact, account: other_account, email: 'alias@example.com', primary: false)

      expect(mismatch).not_to be_valid
      expect(mismatch.errors[:account]).to be_present
    end

    it 'rejects zero-primary or multi-primary states for contacts with email rows' do
      primary_email = create(:contact_email, contact: contact, account: account, email: 'one@example.com', primary: true)
      duplicate_primary = build(:contact_email, contact: contact, account: account, email: 'two@example.com', primary: true)

      expect(duplicate_primary).not_to be_valid
      expect(duplicate_primary.errors[:primary]).to be_present

      # rubocop:disable Rails/SkipsModelValidations
      primary_email.update_column(:primary, false)
      # rubocop:enable Rails/SkipsModelValidations

      expect(contact.reload).not_to be_valid
      expect(contact.errors[:contact_emails]).to be_present
    end

    it 'rejects direct writes that would leave a contact with email rows but no primary' do
      primary_email = create(:contact_email, contact: contact, account: account, email: 'one@example.com', primary: true)
      create(:contact_email, contact: contact, account: account, email: 'two@example.com', primary: false)

      primary_email.primary = false

      expect(primary_email).not_to be_valid
      expect(primary_email.errors[:contact]).to be_present
    end

    it 'prevents destroying the primary row while aliases remain' do
      primary_email = create(:contact_email, contact: contact, account: account, email: 'one@example.com', primary: true)
      create(:contact_email, contact: contact, account: account, email: 'two@example.com', primary: false)

      expect { primary_email.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(contact.reload.contact_emails.pluck(:email, :primary)).to contain_exactly(
        ['one@example.com', true],
        ['two@example.com', false]
      )
    end
  end
end
