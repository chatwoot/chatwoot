require 'rails_helper'

RSpec.describe Webhooks::CalendlyController, type: :controller do
  let(:account) { create(:account) }
  let(:signing_key) { SecureRandom.hex(32) }
  let!(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'calendly',
           access_token: 'test-token',
           settings: {
             'calendly_user_uri' => 'https://api.calendly.com/users/ABC123',
             'calendly_organization_uri' => 'https://api.calendly.com/organizations/ORG123',
             'signing_key' => signing_key,
             'refresh_token' => 'test-refresh',
             'token_expires_at' => 3.hours.from_now.iso8601
           })
  end

  let(:webhook_payload) do
    {
      event: 'invitee.created',
      created_by: 'https://api.calendly.com/users/ABC123',
      created_at: Time.current.iso8601,
      payload: {
        email: 'customer@example.com',
        name: 'John Doe',
        event: 'https://api.calendly.com/scheduled_events/EV123',
        status: 'active',
        uri: 'https://api.calendly.com/scheduled_events/EV123/invitees/INV123'
      }
    }
  end

  def generate_signature(body, key, timestamp = Time.current.to_i.to_s)
    signature = OpenSSL::HMAC.hexdigest('SHA256', key, "#{timestamp}.#{body}")
    "t=#{timestamp},v1=#{signature}"
  end

  describe 'POST #receive' do
    it 'processes valid webhook with correct signature' do
      body = webhook_payload.to_json
      signature = generate_signature(body, signing_key)

      request.headers['Calendly-Webhook-Signature'] = signature
      request.headers['Content-Type'] = 'application/json'

      expect(Integrations::Calendly::WebhookJob).to receive(:perform_later)
        .with(hook, 'invitee.created', anything)

      post :receive, body: body
      expect(response).to have_http_status(:ok)
    end

    it 'rejects webhook with invalid signature' do
      body = webhook_payload.to_json
      signature = generate_signature(body, 'wrong-key')

      request.headers['Calendly-Webhook-Signature'] = signature
      request.headers['Content-Type'] = 'application/json'

      post :receive, body: body
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects webhook with missing signature' do
      body = webhook_payload.to_json
      request.headers['Content-Type'] = 'application/json'

      post :receive, body: body
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects webhook with unknown user URI' do
      payload = webhook_payload.merge(created_by: 'https://api.calendly.com/users/UNKNOWN')
      body = payload.to_json
      signature = generate_signature(body, signing_key)

      request.headers['Calendly-Webhook-Signature'] = signature
      request.headers['Content-Type'] = 'application/json'

      post :receive, body: body
      expect(response).to have_http_status(:unauthorized)
    end

    context 'with stale timestamp' do
      it 'rejects a webhook with a timestamp older than 5 minutes' do
        stale_time = 10.minutes.ago
        body = webhook_payload.to_json
        signature = generate_signature(body, signing_key, stale_time.to_i.to_s)

        request.headers['Calendly-Webhook-Signature'] = signature
        request.headers['Content-Type'] = 'application/json'

        post :receive, body: body
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with future timestamp' do
      it 'rejects a webhook with a timestamp more than 1 minute in the future' do
        future_time = 2.minutes.from_now
        body = webhook_payload.to_json
        signature = generate_signature(body, signing_key, future_time.to_i.to_s)

        request.headers['Calendly-Webhook-Signature'] = signature
        request.headers['Content-Type'] = 'application/json'

        post :receive, body: body
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when processing raises an error' do
      it 'returns 500 so Calendly can retry' do
        body = webhook_payload.to_json
        signature = generate_signature(body, signing_key)

        request.headers['Calendly-Webhook-Signature'] = signature
        request.headers['Content-Type'] = 'application/json'

        allow(Integrations::Calendly::WebhookJob).to receive(:perform_later).and_raise(StandardError, 'Redis down')

        post :receive, body: body
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
