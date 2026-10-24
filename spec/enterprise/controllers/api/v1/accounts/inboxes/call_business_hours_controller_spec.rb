require 'rails_helper'

RSpec.describe 'Call business hours API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_business_hours" }
  let(:params) { { business_hours_calls_enabled: true, out_of_hours_call_message: ' Call again tomorrow. ' } }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(false)
  end

  it 'allows administrators to save settings and returns the trimmed announcement' do
    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('business_hours_calls_enabled' => true, 'out_of_hours_call_message' => 'Call again tomorrow.')
  end

  it 'generates and saves audio with the edited text in one request' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService, perform: 'new audio')
    expect(Llm::TextToSpeechService).to receive(:new).with(text: 'Call again tomorrow.', account: account).and_return(generator)

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(inbox.reload.out_of_hours_call_audio.download).to eq('new audio')
    expect(response.parsed_body.fetch('out_of_hours_call_audio_url')).to include('.mp3')
    expect(channel.reload.out_of_hours_call_message).to eq('Call again tomorrow.')
  end

  it 'preserves active audio when generation fails' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService)
    allow(Llm::TextToSpeechService).to receive(:new).and_return(generator)
    allow(generator).to receive(:perform).and_raise(Faraday::ServerError, 'Generation failed')
    inbox.out_of_hours_call_audio.attach(io: StringIO.new('active'), filename: 'active.mp3', content_type: 'audio/mpeg')
    active = inbox.out_of_hours_call_audio.blob

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:internal_server_error)
    expect(inbox.reload.out_of_hours_call_audio.blob).to eq(active)
  end

  it 'does not allow agents to change the settings' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, inbox: inbox, user: agent)

    patch url, headers: agent.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(channel.reload).not_to be_business_hours_calls_enabled
  end

  it 'preserves the saved announcement and settings when generated audio has a mismatched transcript' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-api-key' }
    channel.update!(provider_config: channel.provider_config.merge(
      'out_of_hours_call_message' => 'Original announcement.', 'business_hours_calls_enabled' => false
    ))
    original_config = channel.provider_config
    inbox.out_of_hours_call_audio.attach(io: StringIO.new('active'), filename: 'active.mp3', content_type: 'audio/mpeg')
    active = inbox.out_of_hours_call_audio.blob
    stub_request(:post, 'https://api.openai.com/v1/chat/completions')
      .to_return(status: 200, body: {
        choices: [{ message: { audio: { data: Base64.strict_encode64('changed audio'), transcript: 'Call tomorrow.' } } }]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body['error']).to eq(I18n.t('errors.voice.announcement_audio_mismatch'))
    expect(channel.reload.provider_config).to eq(original_config)
    expect(inbox.reload.out_of_hours_call_audio.blob).to eq(active)
    expect(inbox.out_of_hours_call_audio.download).to eq('active')
  end

  it 'does not expose another account inbox' do
    other_admin = create(:user, account: create(:account), role: :administrator)
    patch url, headers: other_admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  [
    { business_hours_calls_enabled: 'true' },
    { out_of_hours_call_message: ['message'] },
    { out_of_hours_call_message: ' ' },
    { out_of_hours_call_message: 'a' * 1001 }
  ].each do |invalid|
    it "rejects invalid settings #{invalid.keys.join(', ')} with #{invalid.values.first.class}" do
      patch url, headers: admin.create_new_auth_token, params: params.merge(invalid), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(channel.reload).not_to be_business_hours_calls_enabled
    end
  end

  it 'rejects inboxes without Twilio voice' do
    allow(Twilio::VoiceTeardownService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceTeardownService, perform: nil))
    channel.update!(voice_enabled: false)

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
