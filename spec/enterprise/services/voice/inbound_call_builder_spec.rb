# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::InboundCallBuilder do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230001') }
  let(:inbox) { channel.inbox }

  let(:from_number) { '+15550001111' }
  let(:to_number) { channel.phone_number }
  let(:call_sid) { 'CA1234567890abcdef' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  def build_and_perform
    described_class.new(
      account: account,
      inbox: inbox,
      from_number: from_number,
      to_number: to_number,
      call_sid: call_sid
    ).perform
  end

  it 'creates a new conversation with inbound ringing attributes' do
    builder = build_and_perform
    conversation = builder.conversation
    expect(conversation).to be_present
    expect(conversation.account_id).to eq(account.id)
    expect(conversation.inbox_id).to eq(inbox.id)
    expect(conversation.identifier).to eq(call_sid)
    expect(conversation.additional_attributes['call_direction']).to eq('inbound')
    expect(conversation.additional_attributes['call_status']).to eq('ringing')
  end

  it 'creates a voice_call message with ringing status' do
    builder = build_and_perform
    conversation = builder.conversation
    msg = conversation.messages.voice_calls.last
    expect(msg).to be_present
    expect(msg.message_type).to eq('incoming')
    expect(msg.content_type).to eq('voice_call')
    expect(msg.content_attributes.dig('data', 'call_sid')).to eq(call_sid)
    expect(msg.content_attributes.dig('data', 'status')).to eq('ringing')
  end

  it 'returns TwiML that informs the caller we are connecting' do
    builder = build_and_perform
    xml = builder.twiml_response
    expect(xml).to include('Please wait while we connect you to an agent')
    expect(xml).to include('<Say')
  end
end
