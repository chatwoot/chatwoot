require 'rails_helper'

RSpec.describe 'Call waiting API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/call_waiting" }
  let(:audio) { fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg') }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  describe 'PATCH /call_waiting' do
    it 'turns the join beep off and returns the inbox' do
      patch url, headers: admin.create_new_auth_token, params: { join_beep_enabled: false }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('call_join_beep_enabled' => false)
      expect(channel.reload.call_join_beep_enabled?).to be(false)
    end

    it 'rejects a join beep setting that is not a boolean' do
      patch url, headers: admin.create_new_auth_token, params: { join_beep_enabled: 'false' }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(channel.reload.call_join_beep_enabled?).to be(true)
    end

    it 'does not allow agents to change the settings' do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: agent)

      patch url, headers: agent.create_new_auth_token, params: { join_beep_enabled: false }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects inboxes without Twilio voice' do
      other_inbox = create(:inbox, account: account)

      patch "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/call_waiting",
            headers: admin.create_new_auth_token, params: { join_beep_enabled: false }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT /call_waiting/audio' do
    it 'saves the uploaded audio and returns its URL' do
      put "#{url}/audio", headers: admin.create_new_auth_token, params: { audio: audio }

      expect(response).to have_http_status(:ok)
      expect(inbox.reload.call_waiting_audio.filename.to_s).to eq('sample.mp3')
      expect(response.parsed_body.fetch('call_waiting_audio_url')).to include('sample.mp3')
    end

    it 'replaces the audio already saved' do
      inbox.call_waiting_audio.attach(io: StringIO.new('old'), filename: 'old.mp3', content_type: 'audio/mpeg')

      put "#{url}/audio", headers: admin.create_new_auth_token, params: { audio: audio }

      expect(response).to have_http_status(:ok)
      expect(inbox.reload.call_waiting_audio.filename.to_s).to eq('sample.mp3')
    end

    it 'rejects files that are not MP3 or WAV' do
      put "#{url}/audio", headers: admin.create_new_auth_token,
                          params: { audio: fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Upload an MP3 or WAV file')
      expect(inbox.reload.call_waiting_audio).not_to be_attached
    end

    it 'rejects a request without a file' do
      put "#{url}/audio", headers: admin.create_new_auth_token, params: { audio: 'music.mp3' }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects files over the size limit' do
      stub_const('Api::V1::Accounts::Inboxes::CallWaitingController::MAX_SIZE', 1.kilobyte)

      put "#{url}/audio", headers: admin.create_new_auth_token, params: { audio: audio }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('The audio file must be 10 MB or smaller')
      expect(inbox.reload.call_waiting_audio).not_to be_attached
    end

    it 'does not allow agents to upload audio' do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: agent)

      put "#{url}/audio", headers: agent.create_new_auth_token, params: { audio: audio }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /call_waiting/audio' do
    it 'removes the saved audio' do
      inbox.call_waiting_audio.attach(io: StringIO.new('old'), filename: 'old.mp3', content_type: 'audio/mpeg')

      delete "#{url}/audio", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('call_waiting_audio_url' => nil)
      expect(inbox.reload.call_waiting_audio).not_to be_attached
    end
  end
end
