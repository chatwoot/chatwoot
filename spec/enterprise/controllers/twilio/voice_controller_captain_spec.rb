require 'rails_helper'

RSpec.describe 'Twilio::VoiceController with Captain answering calls', type: :request do
  let(:account) { create(:account, limits: { 'captain_responses' => 10 }) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230098') }
  let(:inbox) { channel.inbox }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:path) { "/twilio/voice/call/#{channel.phone_number.delete_prefix('+')}" }
  let(:params) { { 'CallSid' => "CA#{SecureRandom.hex(16)}", 'From' => '+15550008888', 'To' => channel.phone_number, 'Direction' => 'inbound' } }
  let(:vapi_twiml) { '<Response><Connect><Stream url="wss://vapi.example/stream"/></Connect></Response>' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    account.enable_features!('captain_integration')
    { 'CAPTAIN_VAPI_API_KEY' => 'vapi-key', 'CAPTAIN_VAPI_PHONE_NUMBER_ID' => 'pn_123', 'CAPTAIN_VAPI_WEBHOOK_SECRET' => 'hook-secret' }
      .each { |name, value| create(:installation_config, name: name, value: value) }
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    channel.update!(provider_config: channel.provider_config.merge('captain_answers_calls' => true))
    create(:user, account: account, role: :agent).tap { |agent| create(:inbox_member, inbox: inbox, user: agent) }
    stub_request(:post, Voice::Captain::VapiClient::API_URL).to_return(
      status: 200, body: { id: 'vapi_call_2', phoneCallProviderDetails: { twiml: vapi_twiml } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def post_call_webhook
    signature = Twilio::Security::RequestValidator.new(channel.auth_token).build_signature_for("http://www.example.com#{path}", params)
    post path, params: params, headers: { 'X-Twilio-Signature' => signature }
  end

  it 'connects a new caller to Captain without ringing agents' do
    expect { post_call_webhook }.not_to change(Call, :count)

    expect(response.body).to eq(vapi_twiml)
  end

  it 'rings agents when the handed-off caller is redirected back' do
    post_call_webhook

    expect { post_call_webhook }.to change(Call, :count).by(1)

    expect(response.body).to include('<Conference')
    expect(Call.last.conversation).to eq(inbox.conversations.last)
  end
end
