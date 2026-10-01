require 'rails_helper'

RSpec.describe '/api/v1/widget/transcription', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }
  let(:audio_file) { fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg') }

  def post_transcription(params)
    post api_v1_widget_transcription_url,
         params: { website_token: web_widget.website_token, **params },
         headers: { 'X-Auth-Token' => token }
  end

  describe 'POST /api/v1/widget/transcription' do
    context 'when the voice recorder feature is disabled for the inbox' do
      before { allow(Widget::AudioTranscriptionConfig).to receive(:configured?).and_return(true) }

      it 'returns forbidden' do
        post_transcription(audio: audio_file)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the voice recorder feature is enabled but no OpenAI key is configured' do
      before do
        web_widget.update!(voice_recorder: true)
        allow(Widget::AudioTranscriptionConfig).to receive(:configured?).and_return(false)
      end

      it 'returns forbidden' do
        post_transcription(audio: audio_file)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the voice recorder feature is disabled for the account' do
      before do
        web_widget.update!(voice_recorder: true)
        account.disable_features!(:voice_recorder)
        allow(Widget::AudioTranscriptionConfig).to receive(:configured?).and_return(true)
      end

      it 'returns forbidden' do
        post_transcription(audio: audio_file)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the voice recorder feature is enabled and configured' do
      let(:transcription_service) { instance_double(Messages::WidgetAudioTranscriptionService) }

      before do
        web_widget.update!(voice_recorder: true)
        account.enable_features!(:voice_recorder)
        allow(Widget::AudioTranscriptionConfig).to receive(:configured?).and_return(true)
        allow(Messages::WidgetAudioTranscriptionService).to receive(:new).and_return(transcription_service)
      end

      it 'returns unprocessable entity when no audio is provided' do
        post_transcription({})

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('No audio provided')
      end

      it 'returns the transcription when the service succeeds' do
        allow(transcription_service).to receive(:perform).and_return({ success: true, transcription: 'Hello world' })

        post_transcription(audio: audio_file)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['transcription']).to eq('Hello world')
      end

      it 'returns an error when the service fails' do
        allow(transcription_service).to receive(:perform).and_return({ error: 'Audio too large for transcription' })

        post_transcription(audio: audio_file)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Audio too large for transcription')
      end
    end
  end
end
