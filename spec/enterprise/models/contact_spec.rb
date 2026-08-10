require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'blocking a contact with an active Captain conversation' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }
    let(:captain_assistant) { create(:captain_assistant, account: account) }
    let(:captain_enabled_inbox) { create(:inbox, account: account) }
    let(:regular_inbox) { create(:inbox, account: account) }
    let(:captain_inbox) do
      create(:captain_inbox, captain_assistant: captain_assistant, inbox: captain_enabled_inbox)
    end
    let!(:captain_conversation) do
      captain_inbox
      create(:conversation, account: account, contact: contact, inbox: captain_enabled_inbox, status: :pending)
    end
    let!(:regular_pending_conversation) do
      create(:conversation, account: account, contact: contact, inbox: regular_inbox, status: :pending)
    end

    it 'resolves the Captain conversation without changing other pending conversations' do
      contact.update!(blocked: true)

      expect(captain_conversation.reload).to be_resolved
      expect(regular_pending_conversation.reload).to be_pending
    end
  end
end
