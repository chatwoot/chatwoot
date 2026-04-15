# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::BaileysWebhooksController, type: :request do
  let(:sidecar_key) { 'test-baileys-sidecar-key' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BAILEYS_SIDECAR_API_KEY', '').and_return(sidecar_key)
  end

  describe 'Sidecar Authentication' do
    it 'rejects webhook without API key' do
      post '/webhooks/baileys/message',
           params: { session_id: 'test' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects webhook with wrong API key' do
      post '/webhooks/baileys/message',
           params: { session_id: 'test' }.to_json,
           headers: {
             'Content-Type' => 'application/json',
             'X-Api-Key' => 'wrong-key'
           }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects webhook with empty API key' do
      post '/webhooks/baileys/message',
           params: { session_id: 'test' }.to_json,
           headers: {
             'Content-Type' => 'application/json',
             'X-Api-Key' => ''
           }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /webhooks/baileys/status' do
    it 'rejects status update without auth' do
      post '/webhooks/baileys/status',
           params: { session_id: 'test', status: 'delivered' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /webhooks/baileys/connection' do
    it 'rejects connection event without auth' do
      post '/webhooks/baileys/connection',
           params: { session_id: 'test', connection: 'open' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /webhooks/baileys/qr' do
    it 'rejects QR event without auth' do
      post '/webhooks/baileys/qr',
           params: { session_id: 'test', qr: 'data' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
