require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController (Whapi partner)', type: :request do
  let(:payload) { { channel_id: 'chan_1', events: [{ type: 'connected', phone: '1234567890' }] } }

  # Ensure partner token fallback does not force signature validation in tests
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('WHAPI_PARTNER_TOKEN').and_return(nil)
  end

  context 'when secret is configured' do
    before do
      allow(ENV).to receive(:[]).with('WHAPI_PARTNER_WEBHOOK_SECRET').and_return('secret')
    end

    it 'rejects when signature header is missing' do
      post '/webhooks/whapi', params: payload
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['message']).to match(/signature missing/)
    end

    it 'accepts when signature is valid (hex)' do
      body = payload.to_json
      signature = OpenSSL::HMAC.hexdigest('sha256', 'secret', body)
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      post '/webhooks/whapi', params: payload, headers: { 'X-Whapi-Signature' => signature }, as: :json
      expect(response).to have_http_status(:success)
      expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
    end
  end

  context 'when secret is not configured' do
    it 'skips signature validation and enqueues job' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whapi', params: payload
      expect(response).to have_http_status(:success)
      expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
    end
  end
end


