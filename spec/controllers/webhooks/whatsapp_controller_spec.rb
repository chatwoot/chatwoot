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
  end

  describe 'POST /webhooks/whatsapp/{:phone_number}' do
    it 'calls the whatsapp events job asynchronously with perform_later when awaitResponse is not present' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      post '/webhooks/whatsapp/123221321', params: { content: 'hello' }

      expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
      expect(response).to have_http_status(:ok)
    end

    context 'when phone number is in inactive list' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890,+9876543210')
      end

      it 'returns service unavailable for inactive phone number in URL params' do
        allow(Rails.logger).to receive(:warn)

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }

        expect(Rails.logger).to have_received(:warn).with('Rejected webhook for inactive WhatsApp number: +1234567890')
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

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }

        expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when awaitResponse param is present' do
      it 'calls the whatsapp events job synchronously' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_now)

        post '/webhooks/whatsapp/123221321', params: { content: 'hello', awaitResponse: true }

        expect(Webhooks::WhatsappEventsJob).to have_received(:perform_now)
        expect(response).to have_http_status(:ok)
      end

      it 'returns 401 when InvalidWebhookVerifyToken is raised' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_now).and_raise(Whatsapp::IncomingMessageBaileysService::InvalidWebhookVerifyToken)

        post '/webhooks/whatsapp/123221321', params: { content: 'hello', awaitResponse: true }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 404 when MessageNotFoundError is raised' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_now).and_raise(Whatsapp::IncomingMessageBaileysService::MessageNotFoundError)

        post '/webhooks/whatsapp/123221321', params: { content: 'hello', awaitResponse: true }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
