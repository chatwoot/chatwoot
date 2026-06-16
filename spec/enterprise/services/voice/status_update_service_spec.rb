# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::StatusUpdateService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230002') }
  let(:inbox) { channel.inbox }
  let(:from_number) { '+15550002222' }
  let(:call_sid) { 'CATESTSTATUS123' }
  let(:contact) { create(:contact, account: account, phone_number: from_number) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: from_number) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let!(:call) do
    create(
      :call,
      account: account,
      inbox: inbox,
      conversation: conversation,
      contact: contact,
      provider_call_id: call_sid
    )
  end
  let!(:message) do
    msg = conversation.messages.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: contact,
      content: 'Voice Call',
      content_type: 'voice_call',
      content_attributes: { 'data' => { 'call_sid' => call_sid, 'status' => 'ringing' } }
    )
    call.update!(message_id: msg.id)
    msg
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  it 'updates the Call and touches the linked message on status transition' do
    previous_updated_at = message.updated_at
    travel 1.second

    described_class.new(
      account: account,
      call_sid: call_sid,
      call_status: 'completed'
    ).perform

    call.reload
    message.reload

    expect(call.status).to eq('completed')
    expect(message.updated_at).to be > previous_updated_at
  end

  it 'normalizes busy to no_answer on the Call' do
    described_class.new(
      account: account,
      call_sid: call_sid,
      call_status: 'busy'
    ).perform

    expect(call.reload.status).to eq('no_answer')
  end

  it 'no-ops when no Call matches the provided call_sid' do
    expect do
      described_class.new(account: account, call_sid: 'UNKNOWN', call_status: 'busy').perform
    end.not_to raise_error
  end
end
