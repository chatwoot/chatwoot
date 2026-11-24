require 'rails_helper'

RSpec.describe 'Enterprise Inboxes API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/:account_id/inboxes' do
    it 'preloads announcement attachments and blobs for the inbox list' do
      channels = create_list(:channel_twilio_sms, 2, account: account)
      channels.each do |channel|
        channel.inbox.unanswered_call_audio.attach(io: StringIO.new('audio'), filename: 'announcement.mp3', content_type: 'audio/mpeg')
      end
      create(:channel_twilio_sms, account: account)
      headers = admin.create_new_auth_token
      attachment_queries = []
      blob_queries = []
      subscriber = lambda do |*args|
        payload = args.last
        blob_queries << payload if payload[:name] == 'ActiveStorage::Blob Load'
        next unless payload[:name] == 'ActiveStorage::Attachment Load'
        next unless payload[:binds].any? { |bind| bind.value_for_database == 'unanswered_call_audio' }

        attachment_queries << payload
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
        get "/api/v1/accounts/#{account.id}/inboxes", headers: headers, as: :json
      end

      expect(response).to have_http_status(:ok)
      expect(attachment_queries.size).to eq(1)
      expect(blob_queries.size).to eq(1)
      announcements = response.parsed_body.fetch('payload').filter_map { |inbox| inbox['unanswered_call_audio_url'] }
      expect(announcements.size).to eq(2)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) do
        { name: 'test', auto_assignment_config: { max_assignment_limit: 10 }, channel: { type: 'web_widget', website_url: 'test.com' } }
      end

      it 'creates a webwidget inbox with auto assignment config' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['auto_assignment_config']['max_assignment_limit']).to eq 10
      end

      it 'creates a voice inbox when administrator' do
        account.enable_features('channel_voice')
        account.save!
        stub_request(:get, %r{api\.twilio\.com/2010-04-01/Accounts/.*/IncomingPhoneNumbers\.json})
          .to_return(status: 200, body: { incoming_phone_numbers: [{ capabilities: { 'voice' => true } }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(instance_double(Twilio::VoiceWebhookSetupService,
                                                                                            perform: "AP#{SecureRandom.hex(16)}"))
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'Voice Inbox',
                       channel: { type: 'voice', phone_number: '+15551234567',
                                  provider_config: { account_sid: "AC#{SecureRandom.hex(16)}",
                                                     auth_token: SecureRandom.hex(16),
                                                     api_key_sid: SecureRandom.hex(8),
                                                     api_key_secret: SecureRandom.hex(16) } } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Voice Inbox')
        expect(response.body).to include('+15551234567')
        # the number must also receive SMS, not just calls
        expect(Channels::Twilio::WebhookSetupJob).to have_been_enqueued
      end

      it 'leaves the twilio number untouched when the inbox fails to save' do
        account.enable_features('channel_voice')
        account.save!
        stub_request(:get, %r{api\.twilio\.com/2010-04-01/Accounts/.*/IncomingPhoneNumbers\.json})
          .to_return(status: 200, body: { incoming_phone_numbers: [{ capabilities: { 'voice' => true } }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(instance_double(Twilio::VoiceWebhookSetupService,
                                                                                            perform: "AP#{SecureRandom.hex(16)}"))
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { channel: { type: 'voice', phone_number: '+15551234567',
                                  provider_config: { account_sid: "AC#{SecureRandom.hex(16)}",
                                                     auth_token: SecureRandom.hex(16),
                                                     api_key_sid: SecureRandom.hex(8),
                                                     api_key_secret: SecureRandom.hex(16) } } },
             as: :json

        expect(response).not_to have_http_status(:success)
        # the rollback discarded the channel, so the number must not be left pointing at us
        expect(Channels::Twilio::WebhookSetupJob).not_to have_been_enqueued
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/:id/set_inbound_calls' do
    before do
      allow(Twilio::VoiceWebhookSetupService).to receive(:new)
        .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    end

    context 'when administrator' do
      it 'disables inbound calls on a Twilio voice inbox' do
        channel = create(:channel_twilio_sms, :with_voice, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_inbound_calls",
             headers: admin.create_new_auth_token,
             params: { inbound_calls_enabled: false },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(channel.reload.inbound_calls_enabled?).to be false
      end

      it 'enables inbound calls on a WhatsApp inbox without re-validating provider config' do
        account.enable_features('channel_voice')
        account.save!
        channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                            validate_provider_config: false, sync_templates: false)
        channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'inbound_calls_enabled' => false))

        post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_inbound_calls",
             headers: admin.create_new_auth_token,
             params: { inbound_calls_enabled: true },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(channel.reload.inbound_calls_enabled?).to be true
      end
    end

    context 'when agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'is forbidden' do
        channel = create(:channel_twilio_sms, :with_voice, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_inbound_calls",
             headers: agent.create_new_auth_token,
             params: { inbound_calls_enabled: false },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(channel.reload.inbound_calls_enabled?).to be true
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/:id/set_call_recording' do
    before do
      allow(Twilio::VoiceWebhookSetupService).to receive(:new)
        .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    end

    context 'when administrator' do
      it 'turns recording and transcription off on a Twilio voice inbox' do
        channel = create(:channel_twilio_sms, :with_voice, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_call_recording",
             headers: admin.create_new_auth_token,
             params: { recording_enabled: false, transcription_enabled: false },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(channel.reload).to have_attributes(recording_enabled?: false, transcription_enabled?: false)
      end
    end

    context 'when the inbox has no calling' do
      it 'is rejected' do
        inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_call_recording",
             headers: admin.create_new_auth_token,
             params: { recording_enabled: false, transcription_enabled: false },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Inbox does not support calling')
      end
    end

    context 'when agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'is forbidden' do
        channel = create(:channel_twilio_sms, :with_voice, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_call_recording",
             headers: agent.create_new_auth_token,
             params: { recording_enabled: false, transcription_enabled: false },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(channel.reload.recording_enabled?).to be true
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/:id/health with WhatsApp calling' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
    end
    let(:health_service) { instance_double(Whatsapp::HealthService, sync_health_status!: { id: 'phone123' }) }
    let(:calling_service) { instance_double(Whatsapp::CallingHealthService, perform: { meta_status: { status: 'disabled' } }) }

    before do
      account.enable_features!('channel_voice')
      allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
      allow(Whatsapp::CallingHealthService).to receive(:new).with(channel: channel).and_return(calling_service)
    end

    it 'adds the calling checks when calling is on' do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true))

      get "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/health", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq('id' => 'phone123', 'calling' => { 'meta_status' => { 'status' => 'disabled' } })
    end

    it 'leaves the calling checks out when calling is off' do
      get "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/health", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).not_to have_key('calling')
      expect(Whatsapp::CallingHealthService).not_to have_received(:new)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inboxes/:id' do
    let(:inbox) { create(:inbox, account: account, auto_assignment_config: { max_assignment_limit: 5 }) }

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) { { name: 'new test inbox', auto_assignment_config: { max_assignment_limit: 10 } } }

      it 'updates inbox with auto assignment config' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['auto_assignment_config']['max_assignment_limit']).to eq 10
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inboxes/:id with WhatsApp call hours' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
    end
    let(:inbox) { channel.inbox }
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}" }
    let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }
    let(:closed_week) { (0..6).map { |day| { day_of_week: day, closed_all_day: true } } }

    before do
      account.enable_features!('channel_voice')
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'business_hours_calls_enabled' => true))
      inbox.update!(working_hours_enabled: true)
      stub_request(:get, settings_url).to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { calling: {} }.to_json)
    end

    def stub_call_hours_update(status)
      stub_request(:post, settings_url).with { |request| JSON.parse(request.body).dig('calling', 'call_hours', 'status') == status }
                                       .to_return(status: 200, body: '{}')
    end

    it 'sends edited business hours to WhatsApp' do
      update = stub_call_hours_update('ENABLED')
      working_hours = [{ day_of_week: 1, open_hour: 9, open_minutes: 0, close_hour: 18, close_minutes: 0 }]

      patch url, headers: admin.create_new_auth_token, params: { working_hours: working_hours }, as: :json

      expect(response).to have_http_status(:success)
      expect(update).to have_been_requested
    end

    it 'sends a new timezone to WhatsApp' do
      update = stub_call_hours_update('ENABLED')

      patch url, headers: admin.create_new_auth_token, params: { timezone: 'Asia/Kolkata' }, as: :json

      expect(update).to have_been_requested
    end

    it 'turns call hours off at WhatsApp when the inbox business hours are turned off' do
      update = stub_call_hours_update('DISABLED')

      patch url, headers: admin.create_new_auth_token, params: { working_hours_enabled: false }, as: :json

      expect(response).to have_http_status(:success)
      expect(update).to have_been_requested
    end

    it 'rolls the whole save back when WhatsApp refuses the hours' do
      stub_request(:post, settings_url).to_return(status: 400, headers: { 'Content-Type' => 'application/json' },
                                                  body: { error: { error_user_msg: 'Invalid timezone_id' } }.to_json)

      patch url, headers: admin.create_new_auth_token, params: { name: 'Renamed', timezone: 'Asia/Kolkata' }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq(I18n.t('inbox.call_hours.whatsapp_failed', error: 'Invalid timezone_id'))
      expect(inbox.reload).to have_attributes(name: be_present, timezone: 'UTC')
      expect(inbox.name).not_to eq('Renamed')
    end

    it 'rejects closing every day and rolls the whole save back' do
      patch url, headers: admin.create_new_auth_token, params: { name: 'Renamed', working_hours: closed_week }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq(I18n.t('inbox.call_hours.closed_every_day'))
      expect(inbox.reload.name).not_to eq('Renamed')
      expect(inbox.working_hours.find_by(day_of_week: 1).closed_all_day).to be(false)
      expect(a_request(:post, settings_url)).not_to have_been_made
    end

    it 'allows closing every day once business hours no longer apply to calls' do
      channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))

      patch url, headers: admin.create_new_auth_token, params: { working_hours: closed_week }, as: :json

      expect(response).to have_http_status(:success)
      expect(a_request(:any, settings_url)).not_to have_been_made
    end

    it 'allows closing every day once the inbox business hours are off, keeping call hours off at WhatsApp' do
      inbox.update!(working_hours_enabled: false)
      whatsapp_week = [{ 'day_of_week' => 'MONDAY', 'open_time' => '0900', 'close_time' => '1700' }]
      whatsapp_hours = { 'status' => 'ENABLED', 'timezone_id' => 'UTC', 'weekly_operating_hours' => whatsapp_week }
      stub_request(:get, settings_url).to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                                 body: { calling: { call_hours: whatsapp_hours } }.to_json)
      update = stub_request(:post, settings_url)
               .with(body: { calling: { call_hours: whatsapp_hours.merge('status' => 'DISABLED') } }.to_json)
               .to_return(status: 200, body: '{}')

      patch url, headers: admin.create_new_auth_token, params: { working_hours: closed_week }, as: :json

      expect(response).to have_http_status(:success)
      expect(update).to have_been_requested
    end

    it 'leaves WhatsApp alone when the rest of the save fails' do
      working_hours = [{ day_of_week: 1, open_hour: 9, open_minutes: 0, close_hour: 18, close_minutes: 0 }]

      patch url, headers: admin.create_new_auth_token, params: { working_hours: working_hours, channel: { phone_number: '' } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(a_request(:post, settings_url)).not_to have_been_made
    end

    it 'leaves WhatsApp alone while calling is off, so closing every day is allowed' do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))

      patch url, headers: admin.create_new_auth_token, params: { working_hours: closed_week }, as: :json

      expect(response).to have_http_status(:success)
      expect(a_request(:any, settings_url)).not_to have_been_made
    end

    it 'keeps calling off and says why when WhatsApp refuses the hours on turning calling back on' do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))
      stub_request(:post, settings_url).to_return(status: 400, headers: { 'Content-Type' => 'application/json' },
                                                  body: { error: { error_user_msg: 'Invalid timezone_id' } }.to_json)

      post "#{url}/enable_whatsapp_calling", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq(I18n.t('inbox.call_hours.whatsapp_failed', error: 'Invalid timezone_id'))
      expect(channel.reload.voice_enabled?).to be(false)
    end

    it 'leaves WhatsApp alone when nothing about the hours changed' do
      patch url, headers: admin.create_new_auth_token, params: { name: 'Support line' }, as: :json

      expect(response).to have_http_status(:success)
      expect(a_request(:any, settings_url)).not_to have_been_made
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/:id/set_whatsapp_callback_permission' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
    end
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/set_whatsapp_callback_permission" }
    let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }

    before do
      account.enable_features!('channel_voice')
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true))
    end

    it 'turns asking callers for permission to call back off at WhatsApp and saves it' do
      update = stub_request(:post, settings_url).with(body: { calling: { callback_permission_status: 'DISABLED' } }.to_json)
                                                .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      post url, headers: admin.create_new_auth_token, params: { enabled: false }, as: :json

      expect(response).to have_http_status(:ok)
      expect(update).to have_been_requested
      expect(channel.reload.provider_config['callback_permission_enabled']).to be(false)
    end

    it "shows WhatsApp's reason and saves nothing when WhatsApp refuses" do
      stub_request(:post, settings_url).to_return(status: 400, headers: { 'Content-Type' => 'application/json' },
                                                  body: { error: { error_user_msg: 'Callback permission is not available' } }.to_json)

      post url, headers: admin.create_new_auth_token, params: { enabled: true }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Callback permission is not available')
      expect(channel.reload.provider_config).not_to have_key('callback_permission_enabled')
    end

    it 'is forbidden for agents' do
      agent = create(:user, account: account, role: :agent)

      post url, headers: agent.create_new_auth_token, params: { enabled: true }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(a_request(:post, settings_url)).not_to have_been_made
    end
  end
end
