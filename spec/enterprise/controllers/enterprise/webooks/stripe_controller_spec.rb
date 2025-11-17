require 'rails_helper'

RSpec.describe 'Enterprise::Webhooks::StripeController', type: :request do
  describe 'POST /enterprise/webhooks/stripe' do
    let(:payload) { { type: 'customer.subscription.updated', content: 'hello' }.to_json }
    let(:event_object) { instance_double(Stripe::Event, type: 'customer.subscription.updated') }

    around do |example|
      ENV['STRIPE_WEBHOOK_SECRET'] = 'test_secret'
      ENV['STRIPE_WEBHOOK_SECRET_V2'] = 'test_secret_v2'
      example.run
      ENV.delete('STRIPE_WEBHOOK_SECRET')
      ENV.delete('STRIPE_WEBHOOK_SECRET_V2')
    end

    it 'call the Enterprise::Billing::HandleStripeEventService with the params' do
      handle_stripe = double
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event_object)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new).and_return(handle_stripe)
      allow(handle_stripe).to receive(:perform)
      post '/enterprise/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json', 'Stripe-Signature' => 'test' }
      expect(handle_stripe).to have_received(:perform).with(event: event_object)
    end

    it 'returns a bad request if the headers are missing' do
      post '/enterprise/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request if the headers are invalid' do
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new('Invalid signature', 'sig'))
      post '/enterprise/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json', 'Stripe-Signature' => 'test' }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
