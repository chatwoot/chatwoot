# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::InboundCallBuilder do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:from_number) { '+15550001111' }
  let(:to_number) { channel.phone_number }
  let(:call_sid) { 'CA1234567890abcdef' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
  end

  def perform_builder
    described_class.perform!(
      account: account,
      inbox: inbox,
      from_number: from_number,
      call_sid: call_sid
    )
  end

  context 'when no existing conversation matches call_sid' do
    it 'creates a new inbound conversation with ringing status' do
      conversation = nil
      expect { conversation = perform_builder }.to change(account.conversations, :count).by(1)

      attrs = conversation.additional_attributes
      expect(conversation.identifier).to eq(call_sid)
      expect(attrs['call_direction']).to eq('inbound')
      expect(attrs['call_status']).to eq('ringing')
      expect(attrs['conference_sid']).to be_present
      expect(attrs.dig('meta', 'initiated_at')).to be_present
      expect(conversation.contact.phone_number).to eq(from_number)
    end

    it 'creates a single voice_call message marked as incoming' do
      conversation = perform_builder
      voice_message = conversation.messages.voice_calls.last

      expect(voice_message).to be_present
      expect(voice_message.message_type).to eq('incoming')
      data = voice_message.content_attributes['data']
      expect(data).to include(
        'call_sid' => call_sid,
        'status' => 'ringing',
        'call_direction' => 'inbound',
        'conference_sid' => conversation.additional_attributes['conference_sid'],
        'from_number' => from_number,
        'to_number' => inbox.channel.phone_number
      )
      expect(data['meta']['created_at']).to be_present
      expect(data['meta']['ringing_at']).to be_present
    end

    it 'sets the contact name to the phone number for new callers' do
      conversation = perform_builder

      expect(conversation.contact.name).to eq(from_number)
    end

    it 'ensures the conversation has a display_id before building the conference SID' do
      allow(Voice::Conference::Name).to receive(:for).and_wrap_original do |original, conversation|
        expect(conversation.display_id).to be_present
        original.call(conversation)
      end

      perform_builder
    end
  end

  context 'when a conversation already exists for the call_sid' do
    let(:contact) { create(:contact, account: account, phone_number: from_number) }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: from_number) }
    let!(:existing_conversation) do
      create(
        :conversation,
        account: account,
        inbox: inbox,
        contact: contact,
        contact_inbox: contact_inbox,
        identifier: call_sid,
        additional_attributes: { 'call_direction' => 'outbound', 'conference_sid' => nil }
      )
    end
    let(:existing_message) do
      create(
        :message,
        account: account,
        inbox: inbox,
        conversation: existing_conversation,
        message_type: :incoming,
        content_type: :voice_call,
        sender: contact,
        content_attributes: { 'data' => { 'call_sid' => call_sid, 'status' => 'queued' } }
      )
    end

    it 'reuses the conversation without creating a duplicate' do
      existing_message
      expect { perform_builder }.not_to change(account.conversations, :count)
      existing_conversation.reload
      expect(existing_conversation.additional_attributes['call_direction']).to eq('inbound')
      expect(existing_conversation.additional_attributes['call_status']).to eq('ringing')
    end

    it 'updates the existing voice call message instead of creating a new one' do
      existing_message
      expect { perform_builder }.not_to(change { existing_conversation.reload.messages.voice_calls.count })
      updated_message = existing_conversation.reload.messages.voice_calls.last

      data = updated_message.content_attributes['data']
      expect(data['status']).to eq('ringing')
      expect(data['call_direction']).to eq('inbound')
    end
  end
end
