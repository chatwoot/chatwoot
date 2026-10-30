require 'rails_helper'

RSpec.describe 'Call routing API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_routing" }
  let(:params) { { ring_strategy: 'sequential', ring_step_seconds: 15, prefer_free_agents: true, call_cooldown_seconds: 30 } }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  it 'returns the defaults on the inbox before anything is saved' do
    get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('ring_strategy' => 'simultaneous', 'ring_step_seconds' => 20, 'prefer_free_agents' => false,
                                            'call_cooldown_seconds' => 0)
  end

  it 'allows administrators to save the routing settings' do
    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('ring_strategy' => 'sequential', 'ring_step_seconds' => 15, 'prefer_free_agents' => true,
                                            'call_cooldown_seconds' => 30)
    expect(channel.reload).to have_attributes(sequential_ringing?: true, ring_step_seconds: 15, prefer_free_agents?: true, call_cooldown_seconds: 30)
  end

  [
    { ring_strategy: 'random' },
    { ring_step_seconds: '15' },
    { ring_step_seconds: 9 },
    { ring_step_seconds: 61 },
    { call_cooldown_seconds: -1 },
    { call_cooldown_seconds: 601 },
    { prefer_free_agents: 'true' }
  ].each do |invalid|
    it "rejects #{invalid.inspect}" do
      patch url, headers: admin.create_new_auth_token, params: params.merge(invalid), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('a ring interval of 10 to 60 seconds')
      expect(channel.reload.sequential_ringing?).to be(false)
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
