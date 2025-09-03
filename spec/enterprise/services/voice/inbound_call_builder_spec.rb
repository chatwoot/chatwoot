# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::InboundCallBuilder do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230001') }
  let(:inbox) { channel.inbox }

  let(:from_number) { '+15550001111' }
  let(:to_number) { channel.phone_number }
  let(:call_sid) { 'CA1234567890abcdef' }

  it 'creates a new conversation and a voice_call message and returns TwiML' do
    builder = described_class.new(
      account: account,
      inbox: inbox,
      from_number: from_number,
      to_number: to_number,
      call_sid: call_sid
    ).perform

    conversation = builder.conversation
    expect(conversation).to be_present
    expect(conversation.account_id).to eq(account.id)
    expect(conversation.inbox_id).to eq(inbox.id)
    expect(conversation.identifier).to eq(call_sid)
    expect(conversation.additional_attributes['call_direction']).to eq('inbound')
    expect(conversation.additional_attributes['call_status']).to eq('ringing')

    msg = conversation.messages.voice_calls.last
    expect(msg).to be_present
    expect(msg.message_type).to eq('incoming')
    expect(msg.content_type).to eq('voice_call')
    expect(msg.content_attributes.dig('data', 'call_sid')).to eq(call_sid)
    expect(msg.content_attributes.dig('data', 'status')).to eq('ringing')

    # TwiML should include conference and status callback url
    with_modified_env FRONTEND_URL: 'https://app.chatwoot.test' do
      xml = builder.twiml_response
      expect(xml).to include('/twilio/voice/call/')
      expect(xml).to include('/twilio/voice/status/')
      expect(xml).to include('<Conference')
    end
  end
end

