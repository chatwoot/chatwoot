# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::WebhooksController, type: :request do
  let(:webhook_secret) { 'test-webhook-secret' }
  let!(:account) { create(:account, hub_client_slug: 'test-slug') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('HUB_WEBHOOK_SECRET', '').and_return(webhook_secret)
  end

  describe 'POST /webhooks/hub' do
    let(:payload) do
      {
        event: 'contact.created',
        client_slug: 'test-slug',
        data: { name: 'Test Contact', email: 'test@example.com' }
      }.to_json
    end

    def hmac_signature(body)
      OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, body)
    end

    it 'rejects webhook without signature' do
      post '/webhooks/hub',
           params: payload,
           headers: { 'Content-Type' => 'application/json' }
      expect(response.status).to be_in([401, 403])
    end

    it 'rejects webhook with invalid signature' do
      post '/webhooks/hub',
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'X-Hub-Signature' => 'invalid-signature'
           }
      expect(response.status).to be_in([401, 403])
    end

    it 'accepts webhook with valid HMAC signature' do
      post '/webhooks/hub',
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'X-Hub-Signature' => hmac_signature(payload)
           }
      expect(response).not_to have_http_status(:unauthorized)
      expect(response).not_to have_http_status(:forbidden)
    end
  end
end
