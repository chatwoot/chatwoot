require 'rails_helper'

RSpec.describe Whatsapp::ContactInfoRequestEligibilityService do
  subject(:availability) { described_class.new(conversation: conversation).availability }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:contact) { create(:contact, account: inbox.account, phone_number: nil) }
  let(:contact_inbox) do
    create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'AE.2109889333218546')
  end
  let(:conversation) do
    create(:conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end

  before do
    create(:message, account: inbox.account, inbox: inbox, conversation: conversation, message_type: :incoming)
  end

  it 'finds a pending request from another conversation on the same BSUID contact inbox' do
    previous_conversation = create(
      :conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :resolved
    )
    create(
      :message,
      account: inbox.account,
      inbox: inbox,
      conversation: previous_conversation,
      message_type: :outgoing,
      status: :sent,
      content_attributes: { whatsapp_contact_info: { type: 'request', state: 'pending' } }
    )

    expect(availability).to include(available: false, reason: 'pending_request', delivery_mode: nil)
  end

  it 'ignores pending requests from another BSUID contact inbox on the merged contact' do
    other_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'AE.3109889333218546')
    other_conversation = create(
      :conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: other_contact_inbox
    )
    create(
      :message,
      account: inbox.account,
      inbox: inbox,
      conversation: other_conversation,
      message_type: :outgoing,
      status: :sent,
      content_attributes: { whatsapp_contact_info: { type: 'request', state: 'pending' } }
    )

    expect(availability).to include(available: true, reason: nil, delivery_mode: 'interactive')
  end

  it 'reuses a supplied reply-window result' do
    allow(conversation).to receive(:can_reply?).and_raise('should use the provided can_reply value')

    result = described_class.new(conversation: conversation, can_reply: true).availability

    expect(result).to include(available: true, reason: nil, delivery_mode: 'interactive')
  end
end
