require 'rails_helper'

RSpec.describe 'Call routing API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_routing" }
  let(:params) do
    { ring_strategy: 'sequential', ring_step_seconds: 15, assignee_rings_first: false, call_cooldown_seconds: 30, business_hours_calls_enabled: true }
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  it 'returns the defaults on the inbox before anything is saved' do
    get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('ring_strategy' => 'simultaneous', 'ring_step_seconds' => 20, 'assignee_rings_first' => true,
                                            'call_cooldown_seconds' => 0, 'business_hours_calls_enabled' => false)
  end

  it 'allows administrators to save the routing settings' do
    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('ring_strategy' => 'sequential', 'ring_step_seconds' => 15, 'assignee_rings_first' => false,
                                            'call_cooldown_seconds' => 30, 'business_hours_calls_enabled' => true)
    expect(channel.reload).to have_attributes(sequential_ringing?: true, ring_step_seconds: 15, assignee_rings_first?: false,
                                              call_cooldown_seconds: 30, business_hours_calls_enabled?: true)
  end

  [
    { ring_strategy: 'random' },
    { ring_step_seconds: '15' },
    { ring_step_seconds: 9 },
    { ring_step_seconds: 61 },
    { call_cooldown_seconds: -1 },
    { call_cooldown_seconds: 601 },
    { assignee_rings_first: 'false' },
    { business_hours_calls_enabled: nil }
  ].each do |invalid|
    it "rejects #{invalid.inspect}" do
      patch url, headers: admin.create_new_auth_token, params: params.merge(invalid), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('a ring interval of 10 to 60 seconds')
      expect(channel.reload.sequential_ringing?).to be(false)
    end
  end

  context 'with a WhatsApp inbox' do
    let(:whatsapp) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
    end
    let(:whatsapp_url) { "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp.inbox.id}/call_routing" }

    before do
      account.enable_features!('channel_voice')
      whatsapp.update!(provider_config: whatsapp.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true))
    end

    it 'saves the same settings without checking the credentials with Meta again' do
      expect(Whatsapp::Providers::WhatsappCloudService).not_to receive(:new)

      patch whatsapp_url, headers: admin.create_new_auth_token, params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('ring_strategy' => 'sequential', 'ring_step_seconds' => 15, 'assignee_rings_first' => false,
                                              'call_cooldown_seconds' => 30, 'business_hours_calls_enabled' => true)
      expect(whatsapp.reload).to have_attributes(sequential_ringing?: true, business_hours_calls_enabled?: true)
    end

    it 'rejects invalid settings' do
      patch whatsapp_url, headers: admin.create_new_auth_token, params: params.merge(ring_step_seconds: 5), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('a ring interval of 10 to 60 seconds')
      expect(whatsapp.reload.sequential_ringing?).to be(false)
    end

    it 'refuses a WhatsApp inbox with calling off' do
      whatsapp.update!(provider_config: whatsapp.provider_config.merge('calling_enabled' => false))

      patch whatsapp_url, headers: admin.create_new_auth_token, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'does not let agents change the settings' do
    create(:inbox_member, user: agent, inbox: inbox)
    patch url, headers: agent.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'refuses an inbox without Twilio voice' do
    sms_inbox = create(:channel_twilio_sms, account: account).inbox
    patch "/api/v1/accounts/#{account.id}/inboxes/#{sms_inbox.id}/call_routing", headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
