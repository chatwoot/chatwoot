require 'rails_helper'

RSpec.describe '/api/v1/widget/transcription', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }
  let(:audio_file) { fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg') }

  # NOTE: scenarios that exercise an enabled account rely on the enterprise
  # Messages::WidgetAudioTranscriptionService, so they live under spec/enterprise.
  # FOSS CI strips enterprise/ + spec/enterprise/, so this file must stay free of
  # any enterprise dependency and only cover the disabled (forbidden) path.
  describe 'POST /api/v1/widget/transcription' do
    context 'when audio transcription is disabled' do
      it 'returns forbidden' do
        post api_v1_widget_transcription_url,
             params: { website_token: web_widget.website_token, audio: audio_file },
             headers: { 'X-Auth-Token' => token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
