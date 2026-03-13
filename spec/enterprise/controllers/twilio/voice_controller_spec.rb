# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Twilio::VoiceController', type: :request do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230003') }
  let(:inbox) { channel.inbox }
  let(:digits) { channel.phone_number.delete_prefix('+') }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  describe 'POST /twilio/voice/call/:phone' do
    let(:call_sid) { 'CA_test_call_sid_123' }
    let(:from_number) { '+15550003333' }
    let(:to_number) { channel.phone_number }

    it 'invokes Voice::InboundCallBuilder for inbound calls and renders conference TwiML' do
      instance_double(Voice::InboundCallBuilder)
      conversation = create(:conversation, account: account, inbox: inbox)

      expect(Voice::InboundCallBuilder).to receive(:perform!).with(
        account: account,
        inbox: inbox,
        from_number: from_number,
        call_sid: call_sid
      ).and_return(conversation)

      post "/twilio/voice/call/#{digits}", params: {
        'CallSid' => call_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'inbound'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<Response>')
      expect(response.body).to include('<Dial>')
    end

    it 'syncs an existing outbound conversation when Twilio sends the PSTN leg' do
      conversation = create(:conversation, account: account, inbox: inbox, identifier: call_sid)
      sync_double = instance_double(Voice::CallSessionSyncService, perform: conversation)

      expect(Voice::CallSessionSyncService).to receive(:new).with(
        hash_including(
          conversation: conversation,
          call_sid: call_sid,
          message_call_sid: conversation.identifier,
          leg: {
            from_number: from_number,
            to_number: to_number,
            direction: 'outbound'
          }
        )
      ).and_return(sync_double)

      post "/twilio/voice/call/#{digits}", params: {
        'CallSid' => call_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'outbound-api'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<Response>')
    end

    it 'uses the parent call SID when syncing outbound-dial legs' do
      parent_sid = 'CA_parent'
      child_sid = 'CA_child'
      conversation = create(:conversation, account: account, inbox: inbox, identifier: parent_sid)
      sync_double = instance_double(Voice::CallSessionSyncService, perform: conversation)

      expect(Voice::CallSessionSyncService).to receive(:new).with(
        hash_including(
          conversation: conversation,
          call_sid: child_sid,
          message_call_sid: parent_sid,
          leg: {
            from_number: from_number,
            to_number: to_number,
            direction: 'outbound'
          }
        )
      ).and_return(sync_double)

      post "/twilio/voice/call/#{digits}", params: {
        'CallSid' => child_sid,
        'ParentCallSid' => parent_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'outbound-dial'
      }

      expect(response).to have_http_status(:ok)
    end

    it 'raises not found when inbox is not present' do
      expect(Voice::InboundCallBuilder).not_to receive(:perform!)
      post '/twilio/voice/call/19998887777', params: {
        'CallSid' => call_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'inbound'
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /twilio/voice/status/:phone' do
    let(:call_sid) { 'CA_status_sid_456' }

    it 'invokes Voice::StatusUpdateService with expected params' do
      service_double = instance_double(Voice::StatusUpdateService, perform: nil)
      expect(Voice::StatusUpdateService).to receive(:new).with(
        hash_including(
          account: account,
          call_sid: call_sid,
          call_status: 'completed',
          payload: hash_including('CallSid' => call_sid, 'CallStatus' => 'completed')
        )
      ).and_return(service_double)
      expect(service_double).to receive(:perform)

      post "/twilio/voice/status/#{digits}", params: {
        'CallSid' => call_sid,
        'CallStatus' => 'completed'
      }

      expect(response).to have_http_status(:no_content)
    end

    it 'raises not found when inbox is not present' do
      expect(Voice::StatusUpdateService).not_to receive(:new)
      post '/twilio/voice/status/18005550101', params: {
        'CallSid' => call_sid,
        'CallStatus' => 'busy'
      }
      expect(response).to have_http_status(:not_found)
    end
  end
end
