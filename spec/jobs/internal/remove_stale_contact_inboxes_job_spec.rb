require 'rails_helper'

describe Internal::RemoveStaleContactInboxesJob do
  subject(:job) { described_class.perform_now }

  it 'deletes stale contact inboxes without conversations older than 3 months' do
    # Create a ContactInbox that should be deleted
    stale_contact_inbox = create(:contact_inbox, created_at: 4.months.ago)

    # Create a ContactInbox with a conversation (should not be deleted)
    contact_inbox_with_conversation = create(:contact_inbox)
    create(:conversation, contact_id: contact_inbox_with_conversation.id)

    expect(ContactInbox.count).to eq(2) # Verify initial count

    described_class.perform_now

    expect(ContactInbox.count).to eq(1) # Verify that the stale ContactInbox was deleted
    expect(ContactInbox.find_by(id: stale_contact_inbox.id)).to be_nil
  end
end
