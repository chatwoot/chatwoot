require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactsService do
  describe '#perform' do
    it 'does not delete stale contacts if REMOVE_STALE_CONTACTS_JOB_STATUS is false' do
      # default value of REMOVE_STALE_CONTACTS_JOB_STATUS is false
      create(:contact, created_at: 3.days.ago)
      create(:contact, created_at: 31.days.ago)
      create(:contact, created_at: 32.days.ago)
      create(:contact, created_at: 33.days.ago)
      create(:contact, created_at: 34.days.ago)

      service = described_class.new
      expect { service.perform }.not_to change(Contact, :count)
    end

    it 'deletes stale contacts when REMOVE_STALE_CONTACTS_JOB_STATUS is true' do
      with_modified_env REMOVE_STALE_CONTACTS_JOB_STATUS: 'true' do
        # Recent contact - should not be deleted
        create(:contact, created_at: 3.days.ago)

        # Stale contacts with NULL values - should be deleted
        create(:contact, email: nil, phone_number: nil, identifier: nil, created_at: 31.days.ago)

        # Stale contacts with empty strings - should be deleted
        create(:contact, email: '', phone_number: '', identifier: '', created_at: 32.days.ago)

        # Mixed NULL and empty strings - should be deleted
        create(:contact, email: nil, phone_number: '', identifier: nil, created_at: 33.days.ago)
        create(:contact, email: '', phone_number: nil, identifier: '', created_at: 34.days.ago)

        service = described_class.new
        expect { service.perform }.to change(Contact, :count).by(-4)
      end
    end

    it 'does not delete contacts with conversations' do
      with_modified_env REMOVE_STALE_CONTACTS_JOB_STATUS: 'true' do
        # Contact with NULL values and conversation
        contact1 = create(:contact, email: nil, phone_number: nil, identifier: nil, created_at: 31.days.ago)
        create(:conversation, contact: contact1)

        # Contact with empty strings and conversation
        contact2 = create(:contact, email: '', phone_number: '', identifier: '', created_at: 31.days.ago)
        create(:conversation, contact: contact2)

        service = described_class.new
        expect { service.perform }.not_to change(Contact, :count)
      end
    end

    it 'does not delete contacts with identification' do
      with_modified_env REMOVE_STALE_CONTACTS_JOB_STATUS: 'true' do
        # Non-empty values
        create(:contact, email: 'test@example.com', created_at: 31.days.ago)
        create(:contact, phone_number: '+1234567890', created_at: 31.days.ago)
        create(:contact, identifier: 'test123', created_at: 31.days.ago)

        # Mixed empty and non-empty values - should not be deleted
        create(:contact, email: 'test@example.com', phone_number: '', identifier: nil, created_at: 31.days.ago)
        create(:contact, email: nil, phone_number: '+1234567890', identifier: '', created_at: 31.days.ago)
        create(:contact, email: '', phone_number: nil, identifier: 'test123', created_at: 31.days.ago)

        service = described_class.new
        expect { service.perform }.not_to change(Contact, :count)
      end
    end
  end
end
