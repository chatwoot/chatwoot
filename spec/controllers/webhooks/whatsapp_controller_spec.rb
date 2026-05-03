require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }

  describe 'GET /webhooks/verify' do
    it 'returns 401 when valid params are not present' do
      get "/webhooks/whatsapp/#{channel.phone_number}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when invalid params' do
      get "/webhooks/whatsapp/#{channel.phone_number}",
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'invalid' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns challenge when valid params' do
      get "/webhooks/whatsapp/#{channel.phone_number}",
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => channel.provider_config['webhook_verify_token'] }
      expect(response.body).to include '123456'
    end

    it 'returns challenge for the global WhatsApp app webhook token' do
      allow(GlobalConfigService).to receive(:load)
        .with('WHATSAPP_WEBHOOK_VERIFY_TOKEN', '')
        .and_return('global-token')

      get '/webhooks/whatsapp',
          params: { 'hub.challenge' => 'global-challenge', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'global-token' }

      expect(response.body).to include 'global-challenge'
    end
  end

  describe 'POST /webhooks/whatsapp/{:phone_number}' do
    it 'call the whatsapp events job with the params' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whatsapp/123221321', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end

    context 'when phone number is in inactive list' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890,+9876543210')
      end

      it 'returns service unavailable for inactive phone number in URL params' do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with('Rejected webhook for inactive WhatsApp number: +1234567890')

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Inactive WhatsApp number')
      end
    end

    context 'when INACTIVE_WHATSAPP_NUMBERS config is not set' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return(nil)
      end

      it 'processes the webhook normally' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
        expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /webhooks/whatsapp' do
    it 'enqueues the whatsapp events job for app-level webhook payloads' do
      payload = {
        object: 'whatsapp_business_account',
        entry: [
          {
            id: '294585820394901',
            changes: [
              {
                field: 'message_template_status_update',
                value: {
                  event: 'APPROVED',
                  message_template_id: '123',
                  message_template_name: 'alerta_movimentacao_processual_v2',
                  message_template_language: 'pt_BR'
                }
              }
            ]
          }
        ]
      }

      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whatsapp', params: payload

      expect(response).to have_http_status(:success)
    end
  end
end
