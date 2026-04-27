require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }

  describe 'GET /webhooks/whatsapp/:phone_number (legacy)' do
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

  describe 'GET /webhooks/whatsapp (default without phone_number)' do
    it 'returns 401 when valid params are not present' do
      get '/webhooks/whatsapp'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when verify token does not match any channel' do
      get '/webhooks/whatsapp',
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'nonexistent_token' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns challenge when verify token matches a whatsapp_cloud channel' do
      get '/webhooks/whatsapp',
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => channel.provider_config['webhook_verify_token'] }
      expect(response.body).to include '123456'
    end

    it 'does not match non-cloud provider channels' do
      non_cloud_channel = create(:channel_whatsapp, provider: 'default', sync_templates: false, validate_provider_config: false)
      get '/webhooks/whatsapp',
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe',
                    'hub.verify_token' => non_cloud_channel.provider_config['webhook_verify_token'] }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /webhooks/whatsapp/{:phone_number} (legacy)' do
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

  describe 'POST /webhooks/whatsapp (default without phone_number)' do
    it 'enqueues the whatsapp events job' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whatsapp', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end

    it 'delegates inactive number check to job when phone_number is absent' do
      allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890')
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      post '/webhooks/whatsapp', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
