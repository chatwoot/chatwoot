require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactsService do
  describe '#perform' do
    let(:account) { create(:account) }

    it 'does not delete contacts with conversations' do
      # Contact with NULL values and conversation
      contact1 = create(:contact, account: account, email: nil, phone_number: nil, identifier: nil, created_at: 31.days.ago)
      create(:conversation, contact: contact1)

      # Contact with empty strings and conversation
      contact2 = create(:contact, account: account, email: '', phone_number: '', identifier: '', created_at: 31.days.ago)
      create(:conversation, contact: contact2)

      service = described_class.new(account: account)
      expect { service.perform }.not_to change(Contact, :count)
    end

    it 'does not delete contacts with identification' do
      create(:contact, :with_email, account: account, phone_number: '', identifier: nil, created_at: 31.days.ago)
      create(:contact, :with_phone_number, account: account, email: nil, identifier: '', created_at: 31.days.ago)
      create(:contact, account: account, identifier: 'test123', created_at: 31.days.ago)

      create(:contact, :with_email, account: account, phone_number: '', identifier: nil, created_at: 31.days.ago)
      create(:contact, :with_phone_number, account: account, email: nil, identifier: nil, created_at: 31.days.ago)
      create(:contact, account: account, email: '', phone_number: nil, identifier: 'test1234', created_at: 31.days.ago)

      service = described_class.new(account: account)
      expect { service.perform }.not_to change(Contact, :count)
    end

    it 'deletes stale contacts' do
      create(:contact, account: account, created_at: 31.days.ago)
      create(:contact, account: account, created_at: 1.day.ago)

      service = described_class.new(account: account)
      expect { service.perform }.to change(Contact, :count).by(-1)
    end
  end
end
