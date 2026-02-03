require 'rails_helper'

RSpec.describe 'Webhooks::MoengageController', type: :request do
  describe 'POST /webhooks/moengage/:webhook_token' do
    let(:webhook_token) { SecureRandom.urlsafe_base64(32) }
    let(:payload) do
      {
        event_name: 'cart_abandoned',
        customer: { email: 'test@example.com' }
      }
    end

    it 'enqueues the MoengageEventsJob with params' do
      allow(Webhooks::MoengageEventsJob).to receive(:perform_later)
      expect(Webhooks::MoengageEventsJob).to receive(:perform_later)

      post "/webhooks/moengage/#{webhook_token}", params: payload, as: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns ok for any webhook token (security - do not reveal valid tokens)' do
      allow(Webhooks::MoengageEventsJob).to receive(:perform_later)

      post '/webhooks/moengage/invalid-token', params: payload, as: :json
      expect(response).to have_http_status(:success)
    end

    it 'includes webhook_token in the job params' do
      allow(Webhooks::MoengageEventsJob).to receive(:perform_later) do |params|
        expect(params['webhook_token']).to eq(webhook_token)
      end

      post "/webhooks/moengage/#{webhook_token}", params: payload, as: :json
    end
  end
end
