# spec/services/remove_stale_contact_inboxes_service_spec.rb

require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactInboxesService do
  describe '#perform' do
    it 'deletes stale contact inboxes' do
      with_modified_env STALE_CONTACT_INBOX_TIME_PERIOD: '120.days.ago' do
        # Create some sample ContactInbox records for testing
        # Replace this with your own setup as needed
        create(:contact_inbox, created_at: 3.days.ago)
        create(:contact_inbox, created_at: 91.days.ago)
        create(:contact_inbox, created_at: 92.days.ago)
        create(:contact_inbox, created_at: 93.days.ago)
        create(:contact_inbox, created_at: 94.days.ago)

        # Create an instance of the service and call the perform method
        service = described_class.new
        expect { service.perform }.to change(ContactInbox, :count).by(-4)
      end
    end
  end
end
