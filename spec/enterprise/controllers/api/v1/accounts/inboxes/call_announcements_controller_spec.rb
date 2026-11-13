require 'rails_helper'

RSpec.describe 'Call announcements API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_announcements/greeting" }
  let(:unanswered_url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_announcements/unanswered" }
  let(:params) { { enabled: true, message: ' Welcome to Acme. ' } }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(false)
  end

  it 'allows administrators to save the greeting and returns the trimmed text' do
    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome to Acme.')
  end

  it 'turns the greeting off with an empty message' do
    channel.update!(provider_config: channel.provider_config.merge('call_greeting_enabled' => true, 'call_greeting_message' => 'Hi'))

    patch url, headers: admin.create_new_auth_token, params: { enabled: false, message: '' }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('call_greeting_enabled' => false, 'call_greeting_message' => '')
  end

  it 'returns the default missed-call message before one is saved' do
    get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('unanswered_call_message' => I18n.t('inbox.call_announcements.default_unanswered'),
                                            'unanswered_call_timeout_seconds' => 60)
    expect(response.parsed_body).not_to have_key('unanswered_calls_enabled')
  end

  it 'saves the missed-call message with its ring time' do
    patch unanswered_url, headers: admin.create_new_auth_token, params: { message: 'Nobody is available.', timeout_seconds: 45 }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('unanswered_call_message' => 'Nobody is available.', 'unanswered_call_timeout_seconds' => 45)
  end

  it 'falls back to the default missed-call message when saved empty' do
    patch unanswered_url, headers: admin.create_new_auth_token, params: { message: ' ', timeout_seconds: 30 }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('unanswered_call_message' => I18n.t('inbox.call_announcements.default_unanswered'),
                                            'unanswered_call_timeout_seconds' => 30)
  end

  ['45', 5, 301, 45.5, nil].each do |timeout|
    it "rejects a ring time of #{timeout.inspect}" do
      patch unanswered_url, headers: admin.create_new_auth_token, params: { message: 'Nobody is available.', timeout_seconds: timeout }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Ring time must be a whole number of seconds between 10 and 300')
      expect(channel.reload.provider_config).not_to have_key('unanswered_call_message')
    end
  end

  it 'is not found for an announcement that does not exist' do
    patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_announcements/voicemail",
          headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:not_found)
  end

  describe 'the out-of-hours message' do
    let(:out_of_hours_url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_announcements/out_of_hours" }

    it 'saves its own text' do
      patch out_of_hours_url, headers: admin.create_new_auth_token, params: { message: ' We are closed. ' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('out_of_hours_call_message' => 'We are closed.')
    end

    it 'goes back to the missed-call message when saved empty' do
      channel.update!(provider_config: channel.provider_config.merge('out_of_hours_call_message' => 'We are closed.'))

      patch out_of_hours_url, headers: admin.create_new_auth_token, params: { message: '' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('out_of_hours_call_message' => '')
      expect(Voice::CallAnnouncement.new(inbox.reload, :out_of_hours).message).to eq(I18n.t('inbox.call_announcements.default_unanswered'))
    end
  end

  it 'generates and saves audio with the edited text in one request' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService, perform: 'new audio')
    expect(Llm::TextToSpeechService).to receive(:new).with(text: 'Nobody is available.', account: account).and_return(generator)

    patch unanswered_url, headers: admin.create_new_auth_token, params: { message: 'Nobody is available.', timeout_seconds: 45 }, as: :json

    expect(response).to have_http_status(:ok)
    expect(inbox.reload.unanswered_call_audio.download).to eq('new audio')
    expect(response.parsed_body.fetch('unanswered_call_audio_url')).to include('.mp3')
    expect(channel.reload.provider_config['unanswered_call_message']).to eq('Nobody is available.')
  end

  it 'preserves active audio when generation fails' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService)
    allow(Llm::TextToSpeechService).to receive(:new).and_return(generator)
    allow(generator).to receive(:perform).and_raise(Faraday::UnauthorizedError, 'Incorrect API key')
    inbox.call_greeting_audio.attach(io: StringIO.new('active'), filename: 'active.mp3', content_type: 'audio/mpeg')
    active = inbox.call_greeting_audio.blob

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body['error']).to eq(I18n.t('errors.voice.announcement_generation_failed'))
    expect(inbox.reload.call_greeting_audio.blob).to eq(active)
  end

  it 'does not allow agents to change the settings' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, inbox: inbox, user: agent)

    patch url, headers: agent.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(Voice::CallAnnouncement.new(inbox.reload, :greeting)).not_to be_enabled
  end

  it 'preserves the saved announcement and settings when generated audio has a mismatched transcript' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-api-key' }
    channel.update!(provider_config: channel.provider_config.merge('call_greeting_message' => 'Original greeting.', 'call_greeting_enabled' => false))
    original_config = channel.provider_config
    inbox.call_greeting_audio.attach(io: StringIO.new('active'), filename: 'active.mp3', content_type: 'audio/mpeg')
    active = inbox.call_greeting_audio.blob
    stub_request(:post, 'https://api.openai.com/v1/chat/completions')
      .to_return(status: 200, body: {
        choices: [{ message: { audio: { data: Base64.strict_encode64('changed audio'), transcript: 'Welcome.' } } }]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body['error']).to eq(I18n.t('errors.voice.announcement_audio_mismatch'))
    expect(channel.reload.provider_config).to eq(original_config)
    expect(inbox.reload.call_greeting_audio.blob).to eq(active)
    expect(inbox.call_greeting_audio.download).to eq('active')
  end

  it 'does not expose another account inbox' do
    other_admin = create(:user, account: create(:account), role: :administrator)
    patch url, headers: other_admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  [
    { enabled: 'true' },
    { message: ['message'] },
    { message: ' ' },
    { message: 'a' * 1001 }
  ].each do |invalid|
    it "rejects invalid greeting settings #{invalid.keys.join(', ')} with #{invalid.values.first.class}" do
      patch url, headers: admin.create_new_auth_token, params: params.merge(invalid), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Voice::CallAnnouncement.new(inbox.reload, :greeting)).not_to be_enabled
    end
  end

  it 'rejects a missed-call message over the length limit' do
    patch unanswered_url, headers: admin.create_new_auth_token, params: { message: 'a' * 1001, timeout_seconds: 45 }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects inboxes without Twilio voice' do
    allow(Twilio::VoiceTeardownService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceTeardownService, perform: nil))
    channel.update!(voice_enabled: false)

    patch url, headers: admin.create_new_auth_token, params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
