require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  describe 'GET /webhooks/verify' do
    it 'returns 404 when valid params are not present' do
      get '/webhooks/instagram/verify'
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when invalid params' do
      with_modified_env WHATSAPP_VERIFY_TOKEN: '123456' do
        get '/webhooks/instagram/verify', params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'invalid' }
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns challenge when valid params' do
      with_modified_env WHATSAPP_VERIFY_TOKEN: '123456' do
        get '/webhooks/instagram/verify', params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => '123456' }
        expect(response.body).to include '123456'
      end
    end
  end

  describe 'POST /webhooks/whatsapp/{:phone_number}' do
    it 'call the whatsapp events job with the params' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whatsapp/123221321', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
