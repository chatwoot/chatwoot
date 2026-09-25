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

  it 'keeps the provider status beside the call status and rebroadcasts the message when only that changes' do
    described_class.new(account: account, call_sid: call_sid, call_status: 'initiated').perform
    touched_at = message.reload.updated_at
    travel_to(1.second.from_now) do
      described_class.new(account: account, call_sid: call_sid, call_status: 'ringing').perform
    end

    expect(call.reload.status).to eq('ringing')
    expect(call.provider_status).to eq('ringing')
    expect(call.push_event_data[:provider_status]).to eq('ringing')
    expect(message.reload.updated_at).to be > touched_at
  end

  it 'ignores a delayed callback for an earlier stage' do
    described_class.new(account: account, call_sid: call_sid, call_status: 'ringing').perform
    described_class.new(account: account, call_sid: call_sid, call_status: 'initiated').perform

    expect(call.reload.provider_status).to eq('ringing')
  end

  it 'does not let a delayed live callback follow a terminal one' do
    described_class.new(account: account, call_sid: call_sid, call_status: 'completed').perform
    Call.where(id: call.id).update_all(status: 'in_progress') # rubocop:disable Rails/SkipsModelValidations
    described_class.new(account: account, call_sid: call_sid, call_status: 'ringing').perform

    expect(call.reload.provider_status).to eq('completed')
  end

  it 'leaves the provider status alone once the call has ended' do
    call.update!(status: 'completed')

    described_class.new(account: account, call_sid: call_sid, call_status: 'completed').perform

    expect(call.reload.provider_status).to be_nil
  end

  it 'no-ops when no Call matches the provided call_sid' do
    expect do
      described_class.new(account: account, call_sid: 'UNKNOWN', call_status: 'busy').perform
    end.not_to raise_error
  end
end
