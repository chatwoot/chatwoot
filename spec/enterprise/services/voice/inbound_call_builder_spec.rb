# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::InboundCallBuilder do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:from_number) { '+15550001111' }
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

  context 'when no existing call matches call_sid' do
    it 'creates a new conversation and Call with ringing status' do
      call = nil
      expect { call = perform_builder }.to change(account.conversations, :count).by(1).and change(Call, :count).by(1)

      aggregate_failures do
        expect(call).to be_a(Call)
        expect(call.provider_call_id).to eq(call_sid)
        expect(call.provider).to eq('twilio')
        expect(call.direction).to eq('incoming')
        expect(call.status).to eq('ringing')
        expect(call.conference_sid).to eq("conf_account_#{account.id}_call_#{call.id}")
        expect(call.meta['initiated_at']).to be_present
        expect(call.contact.phone_number).to eq(from_number)
      end
    end

    it 'creates a voice_call message matched to the call and linked via message_id' do
      call = perform_builder
      voice_message = call.conversation.messages.voice_calls.last

      aggregate_failures do
        expect(voice_message).to be_present
        expect(voice_message.message_type).to eq('incoming')
        expect(call.message_id).to eq(voice_message.id)
        expect(voice_message.call).to eq(call)
      end
    end

    it 'sets the contact name to the phone number for new callers' do
      call = perform_builder

      expect(call.contact.name).to eq(from_number)
    end

    it 'does not set conversation.identifier or write call state to additional_attributes' do
      call = perform_builder
      conversation = call.conversation

      expect(conversation.identifier).to be_nil
      expect(conversation.additional_attributes).not_to include('call_status', 'call_direction', 'conference_sid')
    end
  end

  context 'when a Call already exists for the call_sid' do
    let(:existing_call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(
        :call,
        account: account,
        inbox: inbox,
        conversation: conversation,
        contact: conversation.contact,
        provider_call_id: call_sid
      )
    end

    it 'returns the existing call without creating a duplicate' do
      existing_call
      expect { perform_builder }.not_to change(Call, :count)
      expect(perform_builder).to eq(existing_call)
    end
  end

  context 'when the inbox has lock_to_single_conversation enabled' do
    let!(:contact) { create(:contact, account: account, phone_number: from_number) }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: from_number) }
    let!(:existing_open_conversation) do
      create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :open)
    end

    before { inbox.update!(lock_to_single_conversation: true) }

    it 'reuses the most recent non-resolved conversation' do
      call = nil
      expect { call = perform_builder }.not_to change(account.conversations, :count)
      expect(call.conversation).to eq(existing_open_conversation)
    end

    it 'still creates a new Call and voice_call message on the reused conversation' do
      expect { perform_builder }.to change(Call, :count).by(1)
                                                        .and change { existing_open_conversation.reload.messages.voice_calls.count }.by(1)
    end
  end
end
