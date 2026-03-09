# spec/services/remove_stale_contact_inboxes_service_spec.rb

require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactInboxesService do
  describe '#perform' do
    it 'does not delete stale contact inboxes if REMOVE_STALE_CONTACT_INBOX_JOB_STATUS is false' do
      # default value of REMOVE_STALE_CONTACT_INBOX_JOB_STATUS is false
      create(:contact_inbox, created_at: 3.days.ago)
      create(:contact_inbox, created_at: 91.days.ago)
      create(:contact_inbox, created_at: 92.days.ago)
      create(:contact_inbox, created_at: 93.days.ago)
      create(:contact_inbox, created_at: 94.days.ago)

      service = described_class.new
      expect { service.perform }.not_to change(ContactInbox, :count)
    end

    it 'deletes stale contact inboxes' do
      with_modified_env REMOVE_STALE_CONTACT_INBOX_JOB_STATUS: 'true' do
        create(:contact_inbox, created_at: 3.days.ago)
        create(:contact_inbox, created_at: 91.days.ago)
        create(:contact_inbox, created_at: 92.days.ago)
        create(:contact_inbox, created_at: 93.days.ago)
        create(:contact_inbox, created_at: 94.days.ago)

        service = described_class.new
        expect { service.perform }.to change(ContactInbox, :count).by(-4)
      end
    end
  end
end
