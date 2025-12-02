require 'rails_helper'

RSpec.describe 'Enterprise::Webhooks::StripeController', type: :request do
  # -------------- Reason ---------------
  # Updated webhook endpoint URL to point to 'extended' instead of 'enterprise'
  # ------------ Original -----------------------
  # describe 'POST /enterprise/webhooks/stripe' do
  # ---------------------------------------------
  # ---------------------- Modification Begin ----------------------
  describe 'POST /extended/webhooks/stripe' do
    # ---------------------- Modification End ----------------------
    let(:params) { { content: 'hello' } }

    it 'call the Enterprise::Billing::HandleStripeEventService with the params' do
      handle_stripe = double
      allow(Stripe::Webhook).to receive(:construct_event).and_return(params)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new).and_return(handle_stripe)
      allow(handle_stripe).to receive(:perform)
      # -------------- Reason ---------------
      # Updated webhook endpoint URL to point to 'extended' instead of 'enterprise'
      # ------------ Original -----------------------
      # post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      # ---------------------------------------------
      # ---------------------- Modification Begin ----------------------
      post '/extended/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      # ---------------------- Modification End ----------------------
      expect(handle_stripe).to have_received(:perform).with(event: params)
    end

    it 'returns a bad request if the headers are missing' do
      # -------------- Reason ---------------
      # Updated webhook endpoint URL to point to 'extended' instead of 'enterprise'
      # ------------ Original -----------------------
      # post '/enterprise/webhooks/stripe', params: params
      # ---------------------------------------------
      # ---------------------- Modification Begin ----------------------
      post '/extended/webhooks/stripe', params: params
      # ---------------------- Modification End ----------------------
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request if the headers are invalid' do
      # -------------- Reason ---------------
      # Updated webhook endpoint URL to point to 'extended' instead of 'enterprise'
      # ------------ Original -----------------------
      # post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      # ---------------------------------------------
      # ---------------------- Modification Begin ----------------------
      post '/extended/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params
      # ---------------------- Modification End ----------------------
      expect(response).to have_http_status(:bad_request)
    end
  end
end
