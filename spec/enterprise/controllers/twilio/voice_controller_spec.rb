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

    context 'with the audio callers and agents hear' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:call) do
        create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider_call_id: call_sid)
      end
      let(:agent_leg_params) do
        { 'CallSid' => 'CA_agent_leg', 'From' => "client:agent-1-account-#{account.id}", 'To' => to_number, 'Direction' => 'inbound',
          'call_sid' => call_sid }
      end

      before { allow(Voice::InboundCallBuilder).to receive(:perform!).and_return(call) }

      def conference = Nokogiri::XML(response.body).at_xpath('/Response/Dial/Conference')

      it 'leaves Twilio defaults on every leg when nothing is set up' do
        post "/twilio/voice/call/#{digits}", params: inbound_call_params
        expect(conference.attributes.keys).not_to include('waitUrl', 'waitMethod', 'beep')

        post "/twilio/voice/call/#{digits}", params: agent_leg_params
        expect(conference.attributes.keys).not_to include('waitUrl', 'waitMethod', 'beep')
      end

      it 'sends an inbound caller to the wait document when a greeting is on, and not the agent' do
        channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome'))

        post "/twilio/voice/call/#{digits}", params: inbound_call_params
        expect(conference['waitUrl']).to eq("http://localhost:3000/twilio/voice/wait/#{digits}")
        expect(conference['waitMethod']).to eq('GET')

        post "/twilio/voice/call/#{digits}", params: agent_leg_params
        expect(conference.attributes.keys).not_to include('waitUrl')
      end

      it 'sends an inbound caller to the wait document when waiting audio is uploaded' do
        inbox.call_waiting_audio.attach(io: StringIO.new('music'), filename: 'music.mp3', content_type: 'audio/mpeg')

        post "/twilio/voice/call/#{digits}", params: inbound_call_params

        expect(conference['waitUrl']).to eq("http://localhost:3000/twilio/voice/wait/#{digits}")
      end

      it 'keeps the default wait on the contact leg of an outbound call' do
        channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome'))
        call.update!(direction: :outgoing, conference_sid: call.default_conference_sid)

        post "/twilio/voice/call/#{digits}",
             params: { 'CallSid' => call_sid, 'From' => to_number, 'To' => from_number, 'Direction' => 'outbound-api' }

        expect(conference.attributes.keys).not_to include('waitUrl')
      end

      it 'silences the join beep on agent legs when it is turned off' do
        channel.update!(provider_config: channel.provider_config.merge('call_join_beep_enabled' => false))

        post "/twilio/voice/call/#{digits}", params: agent_leg_params
        expect(conference['beep']).to eq('false')

        post "/twilio/voice/call/#{digits}", params: inbound_call_params
        expect(conference.attributes.keys).not_to include('beep')
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

      post "/twilio/voice/call/#{digits}", params: {
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

    # An inbox that predates the setting carries no key in provider_config and must keep recording.
    it 'records the conference from the start when the call was created with recording on' do
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider_call_id: call_sid)
      allow(Voice::InboundCallBuilder).to receive(:perform!).and_return(call)

      post "/twilio/voice/call/#{digits}", params: inbound_call_params

      expect(response.body).to include('record="record-from-start"')
    end

    it 'does not record the conference when the call was created with recording off' do
      channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))
      conversation = create(:conversation, account: account, inbox: inbox)
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider_call_id: call_sid)
      allow(Voice::InboundCallBuilder).to receive(:perform!).and_return(call)

      post "/twilio/voice/call/#{digits}", params: inbound_call_params

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

      post "/twilio/voice/call/#{digits}", params: {
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

      post "/twilio/voice/call/#{digits}", params: {
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

      post "/twilio/voice/call/#{digits}", params: {
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

      post "/twilio/voice/call/#{digits}", params: {
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

      post "/twilio/voice/call/#{digits}", params: {
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
      post '/twilio/voice/call/19998887777', params: {
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
        post "/twilio/voice/call/#{digits}", params: {
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

  describe 'GET /twilio/voice/wait/:phone' do
    def elements = Nokogiri::XML(response.body).at_xpath('/Response').elements

    it 'hands a caller over to the playlist Twilio plays by default when nothing is set up' do
      get "/twilio/voice/wait/#{digits}"

      expect(response).to have_http_status(:ok)
      expect(elements.map(&:name)).to eq(['Redirect'])
      expect(elements.first.text).to eq('https://s3.amazonaws.com/com.twilio.sounds.music/index.xml')
      expect(elements.first['method']).to eq('GET')
    end

    it 'reads the greeting once, then hands over to the default playlist' do
      channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome to Acme'))

      get "/twilio/voice/wait/#{digits}"

      expect(elements.map(&:name)).to eq(%w[Say Redirect])
      expect(elements.first.text).to eq('Welcome to Acme')
    end

    it 'plays the generated greeting once, then loops the uploaded waiting audio' do
      channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome'))
      inbox.call_greeting_audio.attach(io: StringIO.new('hello'), filename: 'greeting.mp3', content_type: 'audio/mpeg')
      inbox.call_waiting_audio.attach(io: StringIO.new('music'), filename: 'music.mp3', content_type: 'audio/mpeg')

      get "/twilio/voice/wait/#{digits}"

      expect(elements.map(&:name)).to eq(%w[Play Play])
      expect(elements.map(&:text)).to all(start_with('http://localhost:3000/rails/active_storage/'))
      expect(elements.first.text).to end_with('/greeting.mp3')
      expect(elements.first['loop']).to be_nil
      expect(elements.last.text).to end_with('/music.mp3')
      expect(elements.last['loop']).to eq('0')
    end

    it 'skips a greeting that is turned off' do
      channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => false, 'call_greeting_message' => 'Welcome'))

      get "/twilio/voice/wait/#{digits}"

      expect(elements.map(&:name)).to eq(['Redirect'])
    end
  end

  describe 'GET /twilio/voice/hold/:phone' do
    def elements = Nokogiri::XML(response.body).at_xpath('/Response').elements

    it 'loops the uploaded waiting audio for a caller on hold, without the greeting' do
      channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome'))
      inbox.call_waiting_audio.attach(io: StringIO.new('music'), filename: 'music.mp3', content_type: 'audio/mpeg')

      get "/twilio/voice/hold/#{digits}"

      expect(elements.map(&:name)).to eq(['Play'])
      expect(elements.first.text).to end_with('/music.mp3')
      expect(elements.first['loop']).to eq('0')
    end

    it "hands a caller on hold to Twilio's playlist when no waiting audio is uploaded" do
      get "/twilio/voice/hold/#{digits}"

      expect(elements.map(&:name)).to eq(['Redirect'])
      expect(elements.first.text).to eq('https://s3.amazonaws.com/com.twilio.sounds.music/index.xml')
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
