# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Twilio::VoiceController', type: :request do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230003') }
  let(:inbox) { channel.inbox }
  let(:digits) { channel.phone_number.delete_prefix('+') }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  def post_twilio_webhook(path, params:)
    validator = Twilio::Security::RequestValidator.new(channel.auth_token)
    signature = validator.build_signature_for("http://www.example.com#{path}", params)
    post path, params: params, headers: { 'X-Twilio-Signature' => signature }
  end

  %w[call status conference_status recording_status].product(%w[missing invalid tampered api_key_secret]).each do |endpoint, signature_type|
    describe "signature verification for #{endpoint}" do
      let!(:call) { create(:call, account: account, inbox: inbox) }
      let(:path) { "/twilio/voice/#{endpoint}/#{digits}" }
      let(:payload) do
        {
          'CallSid' => call.provider_call_id,
          'From' => '+15550003333',
          'To' => channel.phone_number,
          'Direction' => 'inbound',
          'CallStatus' => 'completed',
          'StatusCallbackEvent' => 'participant-join',
          'FriendlyName' => call.default_conference_sid,
          'ConferenceSid' => 'CF_test_conference',
          'RecordingStatus' => 'completed',
          'RecordingSid' => 'RE_test_recording',
          'RecordingUrl' => 'https://api.twilio.com/test-recording'
        }
      end

      it "rejects a #{signature_type} signature without processing the callback" do
        token = signature_type == 'api_key_secret' ? channel.api_key_secret : channel.auth_token
        signature = Twilio::Security::RequestValidator.new(token).build_signature_for("http://www.example.com#{path}", payload)
        headers = { 'X-Twilio-Signature' => signature }
        headers = {} if signature_type == 'missing'
        headers['X-Twilio-Signature'] = 'invalid' if signature_type == 'invalid'
        request_payload = signature_type == 'tampered' ? payload.merge('CallStatus' => 'busy') : payload
        original_attributes = call.attributes

        expect(Voice::InboundCallBuilder).not_to receive(:perform!)
        expect(Voice::StatusUpdateService).not_to receive(:new)
        expect(Voice::Conference::Manager).not_to receive(:new)
        expect(Voice::RecordingStatusService).not_to receive(:new)

        expect do
          post path, params: request_payload, headers: headers
        end.not_to change(Call, :count)

        expect(response).to have_http_status(:forbidden)
        expect(call.reload.attributes).to eq(original_attributes)
      end
    end
  end

  describe 'POST /twilio/voice/call/:phone' do
    let(:call_sid) { 'CA_test_call_sid_123' }
    let(:from_number) { '+15550003333' }
    let(:to_number) { channel.phone_number }
    let(:inbound_call_params) { { 'CallSid' => call_sid, 'From' => from_number, 'To' => to_number, 'Direction' => 'inbound' } }

    context 'when outside business hours' do
      before do
        inbox.update!(working_hours_enabled: true, timezone: 'America/Los_Angeles')
        inbox.working_hours.each { |hours| hours.update!(closed_all_day: true, open_all_day: false) }
        channel.update!(provider_config: channel.provider_config.merge(
          'business_hours_calls_enabled' => true,
          'out_of_hours_call_message' => 'Please call during business hours.'
        ))
      end

      it 'announces closure and hangs up without ringing agents, including on retries' do
        account.enable_features!('channel_voice', 'mobile_voice_push')
        expect(Voice::VoipPushService).not_to receive(:recipients_for)

        2.times { post "/twilio/voice/call/#{digits}", params: inbound_call_params }

        xml = Nokogiri::XML(response.body)
        expect(xml.at_xpath('//Say').text).to eq('Please call during business hours.')
        expect(xml.at_xpath('//Hangup')).to be_present
        expect(xml.at_xpath('//Dial')).to be_nil
        call = inbox.calls.sole
        expect(call).to have_attributes(status: 'no_answer', end_reason: 'outside_working_hours', ring_state: {})
        expect(Voice::VoipPushJob).not_to have_been_enqueued
        expect(Voice::MissedCallNotificationJob).not_to have_been_enqueued
      end

      it 'plays the saved generated audio before hanging up' do
        inbox.out_of_hours_call_audio.attach(io: StringIO.new('audio'), filename: 'announcement.mp3', content_type: 'audio/mpeg')

        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        xml = Nokogiri::XML(response.body)
        expect(xml.at_xpath('//Play').text).to include('announcement.mp3')
        expect(xml.at_xpath('//Hangup')).to be_present
        expect(xml.at_xpath('//Say')).to be_nil
      end

      it 'reads the text fallback using the account language' do
        account.update!(locale: 'de')
        channel.update!(provider_config: channel.provider_config.merge('out_of_hours_call_message' => 'Bitte rufen Sie morgen an.'))

        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        announcement = Nokogiri::XML(response.body).at_xpath('//Say')
        expect(announcement.text).to eq('Bitte rufen Sie morgen an.')
        expect(announcement['language']).to eq('de-DE')
      end

      it 'uses a supported default for account languages unavailable in the basic Twilio voice' do
        account.update!(locale: 'ml')

        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        expect(Nokogiri::XML(response.body).at_xpath('//Say')['language']).to eq('en-US')
      end

      it 'rings normally when applying business hours to calls is disabled' do
        channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))

        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        expect(Nokogiri::XML(response.body).at_xpath('//Conference')).to be_present
        expect(inbox.calls.sole).to have_attributes(status: 'ringing', end_reason: nil)
      end

      it 'rings normally during business hours in the inbox timezone' do
        travel_to Time.utc(2026, 10, 19, 19) do
          inbox.working_hours.find_by!(day_of_week: 1).update!(closed_all_day: false, open_hour: 9, open_minutes: 0,
                                                               close_hour: 17, close_minutes: 0)

          post "/twilio/voice/call/#{digits}", params: inbound_call_params

          expect(Nokogiri::XML(response.body).at_xpath('//Conference')).to be_present
          expect(inbox.calls.sole).to be_ringing
        end
      end
    end

    it 'invokes Voice::InboundCallBuilder for inbound calls and renders conference TwiML' do
      conversation = create(:conversation, account: account, inbox: inbox)
      contact = conversation.contact
      call = create(
        :call,
        account: account,
        inbox: inbox,
        conversation: conversation,
        contact: contact,
        provider_call_id: call_sid
      )
      call.update!(conference_sid: call.default_conference_sid)

      expect(Voice::InboundCallBuilder).to receive(:perform!).with(
        inbox: inbox,
        call_sid: call_sid,
        caller: { source_ids: [from_number], contact_attributes: { name: from_number, phone_number: from_number } }
      ).and_return(call)

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => call_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'inbound'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<Response>')
      expect(response.body).to include('<Dial>')
      expect(response.body).to include(call.conference_sid)
    end

    context 'when the caller withholds their number' do
      let(:call_sid) { "CA#{SecureRandom.hex(16)}" }
      let(:from_number) { 'anonymous' }

      it 'answers with conference TwiML and a phone-less contact' do
        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        call = Call.find_by!(provider_call_id: call_sid)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<Dial>', call.conference_sid)
        expect(call.contact).to have_attributes(name: 'Unknown caller', phone_number: nil)
        expect(call.conversation.can_reply?).to be false
      end

      it 'creates separate contacts and conversations for separate calls' do
        post "/twilio/voice/call/#{digits}", params: inbound_call_params
        first = Call.find_by!(provider_call_id: call_sid)
        second_sid = "CA#{SecureRandom.hex(16)}"

        post "/twilio/voice/call/#{digits}", params: inbound_call_params.merge('CallSid' => second_sid)
        second = Call.find_by!(provider_call_id: second_sid)

        expect(response).to have_http_status(:ok)
        expect(second.contact).not_to eq(first.contact)
        expect(second.conversation).not_to eq(first.conversation)
      end

      it 'reuses the call, contact and conversation when Twilio retries' do
        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        expect do
          post "/twilio/voice/call/#{digits}", params: inbound_call_params
        end.not_to(change { [Call.count, Contact.count, Conversation.count] })
        expect(response).to have_http_status(:ok)
      end
    end

    # An inbox that predates the setting carries no key in provider_config and must keep recording.
    it 'records the conference from the start when the call was created with recording on' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider_call_id: call_sid)
      allow(Voice::InboundCallBuilder).to receive(:perform!).and_return(call)

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: inbound_call_params

      expect(response.body).to include('record="record-from-start"')
    end

    it 'does not record the conference when the call was created with recording off' do
      channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider_call_id: call_sid)
      allow(Voice::InboundCallBuilder).to receive(:perform!).and_return(call)

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: inbound_call_params

      expect(response.body).to include('record="do-not-record"')
    end

    it 'looks up the Call when Twilio sends the outbound-api PSTN leg' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(
        :call,
        account: account,
        inbox: inbox,
        conversation: conversation,
        contact: conversation.contact,
        direction: :outgoing,
        provider_call_id: call_sid
      )
      call.update!(conference_sid: call.default_conference_sid)

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => call_sid,
        'From' => to_number,
        'To' => from_number,
        'Direction' => 'outbound-api'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(call.conference_sid)
      expect(call.reload.parent_call_sid).to be_nil
    end

    it 'hangs up an outbound PSTN leg answered after the call already ended' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(
        :call,
        account: account,
        inbox: inbox,
        conversation: conversation,
        contact: conversation.contact,
        direction: :outgoing,
        provider_call_id: call_sid,
        status: 'rejected'
      )

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => call_sid,
        'From' => to_number,
        'To' => from_number,
        'Direction' => 'outbound-api'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<Hangup/>')
      expect(response.body).not_to include('<Dial>')
      expect(call.reload.conference_sid).to be_nil
    end

    it 'records the agent leg as on its way in' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                           provider_call_id: call_sid, status: 'ringing')

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => 'CA_agent_leg', 'From' => "client:agent-1-account-#{account.id}", 'To' => to_number,
        'Direction' => 'inbound', 'call_sid' => call_sid
      }

      expect(response.body).to include('<Dial>')
      expect(call.reload.agent_legs.dig('CA_agent_leg', 'state')).to eq('joining')
    end

    it 'hangs up an agent leg for a call that has ended, without recording it' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                           provider_call_id: call_sid, status: 'no_answer')

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => 'CA_agent_leg', 'From' => "client:agent-1-account-#{account.id}", 'To' => to_number,
        'Direction' => 'inbound', 'call_sid' => call_sid
      }

      expect(response.body).to include('<Hangup/>')
      expect(call.reload.agent_legs).to be_empty
    end

    it 'records the parent call SID when syncing outbound-dial legs' do
      parent_sid = 'CA_parent'
      child_sid = 'CA_child'
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(
        :call,
        account: account,
        inbox: inbox,
        conversation: conversation,
        contact: conversation.contact,
        direction: :outgoing,
        provider_call_id: parent_sid
      )
      call.update!(conference_sid: call.default_conference_sid)

      post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
        'CallSid' => child_sid,
        'ParentCallSid' => parent_sid,
        'From' => to_number,
        'To' => from_number,
        'Direction' => 'outbound-dial'
      }

      expect(response).to have_http_status(:ok)
      expect(call.reload.parent_call_sid).to eq(parent_sid)
    end

    it 'keeps a provider status written while the parent call sid is recorded' do
      parent_sid = 'CA_PARENT_RACE'
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                           direction: :outgoing, provider_call_id: parent_sid)
      call.update!(conference_sid: call.default_conference_sid)
      stale_copy = Call.find(call.id)
      Call.where(id: call.id).update_all("meta = meta || '{\"provider_status\": \"ringing\"}'::jsonb") # rubocop:disable Rails/SkipsModelValidations

      stale_copy.merge_meta!('parent_call_sid' => parent_sid)

      expect(call.reload).to have_attributes(parent_call_sid: parent_sid, provider_status: 'ringing')
    end

    it 'raises not found when inbox is not present' do
      expect(Voice::InboundCallBuilder).not_to receive(:perform!)
      post_twilio_webhook '/twilio/voice/call/19998887777', params: {
        'CallSid' => call_sid,
        'From' => from_number,
        'To' => to_number,
        'Direction' => 'inbound'
      }
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects the inbound contact leg without building a call when inbound calls are disabled' do
      channel.update!(provider_config: { 'inbound_calls_enabled' => false })
      expect(Voice::InboundCallBuilder).not_to receive(:perform!)

      expect do
        post_twilio_webhook "/twilio/voice/call/#{digits}", params: {
          'CallSid' => call_sid,
          'From' => from_number,
          'To' => to_number,
          'Direction' => 'inbound'
        }
      end.not_to change(Call, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<Reject')
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

      post_twilio_webhook "/twilio/voice/status/#{digits}", params: {
        'CallSid' => call_sid,
        'CallStatus' => 'completed'
      }

      expect(response).to have_http_status(:no_content)
    end

    it 'raises not found when inbox is not present' do
      expect(Voice::StatusUpdateService).not_to receive(:new)
      post_twilio_webhook '/twilio/voice/status/18005550101', params: {
        'CallSid' => call_sid,
        'CallStatus' => 'busy'
      }
      expect(response).to have_http_status(:not_found)
    end
  end
end
