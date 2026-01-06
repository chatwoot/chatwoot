# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::OutboundCallBuilder do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230000') }
  let(:inbox) { channel.inbox }
  let(:user) { create(:user, account: account) }
  let(:contact) { create(:contact, account: account, phone_number: '+15550001111') }
  let(:call_sid) { 'CA1234567890abcdef' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(inbox).to receive(:channel).and_return(channel)
    allow(channel).to receive(:initiate_call).and_return({ call_sid: call_sid })
    allow(Voice::Conference::Name).to receive(:for).and_call_original
  end

  describe '.perform!' do
    it 'creates a conversation and voice call message' do
      conversation_count = account.conversations.count
      inbox_link_count = contact.contact_inboxes.where(inbox_id: inbox.id).count

      result = described_class.perform!(
        account: account,
        inbox: inbox,
        user: user,
        contact: contact
      )

      expect(account.conversations.count).to eq(conversation_count + 1)
      expect(contact.contact_inboxes.where(inbox_id: inbox.id).count).to eq(inbox_link_count + 1)

      conversation = result[:conversation].reload
      attrs = conversation.additional_attributes

      aggregate_failures do
        expect(result[:call_sid]).to eq(call_sid)
        expect(conversation.identifier).to eq(call_sid)
        expect(attrs).to include('call_direction' => 'outbound', 'call_status' => 'ringing')
        expect(attrs['agent_id']).to eq(user.id)
        expect(attrs['conference_sid']).to be_present

        voice_message = conversation.messages.voice_calls.last
        expect(voice_message.message_type).to eq('outgoing')

        message_data = voice_message.content_attributes['data']
        expect(message_data).to include(
          'call_sid' => call_sid,
          'conference_sid' => attrs['conference_sid'],
          'from_number' => channel.phone_number,
          'to_number' => contact.phone_number
        )
      end
    end

    it 'raises an error when contact is missing a phone number' do
      contact.update!(phone_number: nil)

      expect do
        described_class.perform!(
          account: account,
          inbox: inbox,
          user: user,
          contact: contact
        )
      end.to raise_error(ArgumentError, 'Contact phone number required')
    end

    it 'raises an error when user is nil' do
      expect do
        described_class.perform!(
          account: account,
          inbox: inbox,
          user: nil,
          contact: contact
        )
      end.to raise_error(ArgumentError, 'Agent required')
    end

    it 'ensures the conversation has a display_id before building the conference SID' do
      allow(Voice::Conference::Name).to receive(:for).and_wrap_original do |original, conversation|
        expect(conversation.display_id).to be_present
        original.call(conversation)
      end

      described_class.perform!(
        account: account,
        inbox: inbox,
        user: user,
        contact: contact
      )
    end
  end
end
