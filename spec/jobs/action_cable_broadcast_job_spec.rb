require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: 'contact@example.com', phone_number: '+15555550100') }
  let(:conversation) { create(:conversation, account: account, contact: contact) }

  before { allow(ActionCable.server).to receive(:broadcast) }

  describe 'for contact sessions' do
    it 'strips contact details from conversation events after refreshing them' do
      described_class.perform_now(['contact-token'], 'conversation.updated',
                                  { account_id: account.id, id: conversation.display_id }, contact_session: true)

      expect(ActionCable.server).to have_received(:broadcast).with(
        'contact-token', hash_including(data: hash_including(id: conversation.display_id, meta: hash_including(sender: { type: 'contact' })))
      )
    end

    it 'strips contact details from message events' do
      message = create(:message, account: account, conversation: conversation, inbox: conversation.inbox,
                                 message_type: :incoming, sender: contact)

      described_class.perform_now(['contact-token'], 'message.created', message.push_event_data.merge(account_id: account.id),
                                  contact_session: true)

      expect(ActionCable.server).to have_received(:broadcast).with(
        'contact-token', hash_including(data: hash_including(id: message.id, sender: { type: 'contact' }))
      )
    end
  end

  it 'keeps contact details for other members' do
    described_class.perform_now(['agent-token'], 'conversation.updated', { account_id: account.id, id: conversation.display_id })

    expect(ActionCable.server).to have_received(:broadcast).with(
      'agent-token', hash_including(data: hash_including(meta: hash_including(sender: hash_including(email: 'contact@example.com'))))
    )
  end
end
