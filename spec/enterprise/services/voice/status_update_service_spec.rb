# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::StatusUpdateService do
  let(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account, phone_number: from_number) }
  let(:contact_inbox) { ContactInbox.create!(contact: contact, inbox: inbox, source_id: from_number) }
  let(:conversation) do
    Conversation.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      identifier: call_sid,
      additional_attributes: { 'call_direction' => 'inbound', 'call_status' => 'ringing' }
    )
  end
  let(:message) do
    conversation.messages.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: contact,
      content: 'Voice Call',
      content_type: 'voice_call',
      content_attributes: { data: { call_sid: call_sid, status: 'ringing' } }
    )
  end
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230002') }
  let(:inbox) { channel.inbox }
  let(:from_number) { '+15550002222' }
  let(:call_sid) { 'CATESTSTATUS123' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  it 'updates conversation and last voice message with call status' do
    # Ensure records are created after stub setup
    conversation
    message

    described_class.new(
      account: account,
      call_sid: call_sid,
      call_status: 'completed'
    ).perform

    conversation.reload
    message.reload

    expect(conversation.additional_attributes['call_status']).to eq('completed')
    expect(message.content_attributes.dig('data', 'status')).to eq('completed')
  end

  it 'no-ops when conversation not found' do
    expect do
      described_class.new(account: account, call_sid: 'UNKNOWN', call_status: 'busy').perform
    end.not_to raise_error
  end
end
