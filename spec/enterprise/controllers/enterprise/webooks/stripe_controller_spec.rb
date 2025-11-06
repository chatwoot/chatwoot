require 'rails_helper'

RSpec.describe 'Enterprise::Webhooks::StripeController', type: :request do
  describe 'POST /enterprise/webhooks/stripe' do
    let(:params) { { content: 'hello' } }
    let(:v1_event_params) { { type: 'invoice.created', data: { object: {} } }.to_json }

    it 'delegates to the v1 handler for legacy events' do
      handle_stripe = instance_double(Enterprise::Billing::HandleStripeEventService)
      event = instance_double(Stripe::Event, type: 'invoice.created')

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new).and_return(handle_stripe)
      allow(handle_stripe).to receive(:perform)

      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: v1_event_params, as: :json

      expect(handle_stripe).to have_received(:perform).with(event: event)
    end

    it 'delegates v2 billing events to the v2 webhook handler' do
      v2_event_params = { type: 'v2.billing.pricing_plan_subscription.servicing_activated', data: { object: {} } }.to_json
      event = instance_double(Stripe::Event, type: 'v2.billing.pricing_plan_subscription.servicing_activated')
      handler_double = instance_double(Enterprise::Billing::V2::WebhookHandlerService, perform: { success: true })

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Enterprise::Billing::V2::WebhookHandlerService).to receive(:new).and_return(handler_double)

      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: v2_event_params, as: :json

      expect(Enterprise::Billing::V2::WebhookHandlerService).to have_received(:new)
      expect(handler_double).to have_received(:perform).with(event: event)
      expect(response).to have_http_status(:ok)
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
