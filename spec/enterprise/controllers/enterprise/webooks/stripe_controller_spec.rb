require 'rails_helper'

RSpec.describe 'Enterprise::Webhooks::StripeController', type: :request do
  describe 'POST /enterprise/webhooks/stripe' do
    let(:params) { { content: 'hello' } }

    it 'call the Enterprise::Billing::HandleStripeEventService with the params' do
      handle_stripe = double
      allow(Stripe::Webhook).to receive(:construct_event).and_return(params)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new).and_return(handle_stripe)
      allow(handle_stripe).to receive(:perform)
      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      expect(handle_stripe).to have_received(:perform).with(event: params)
    end

    it 'returns a bad request if the headers are missing' do
      post '/enterprise/webhooks/stripe', params: params
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request if the headers are invalid' do
      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      expect(response).to have_http_status(:bad_request)
    end
  end
end
