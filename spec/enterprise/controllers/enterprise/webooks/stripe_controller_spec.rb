require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles

RSpec.describe 'Enterprise::Webhooks::StripeController', type: :request do
  describe 'POST /enterprise/webhooks/stripe' do
    let(:params) { { content: 'hello' } }

    it 'delegates to the v1 handler for legacy events' do
      handle_stripe = double
      event = double('Stripe::Event', type: 'invoice.created')

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new).and_return(handle_stripe)
      allow(handle_stripe).to receive(:perform)

      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params

      expect(handle_stripe).to have_received(:perform).with(event: event)
    end

    it 'delegates v2 billing events to the v2 webhook handler' do
      account = create(:account)
      account.update!(custom_attributes: (account.custom_attributes || {}).merge(
        'stripe_billing_version' => 2,
        'stripe_customer_id' => 'cus_123'
      ))

      event_object = double('StripeObject', customer: 'cus_123')
      event = double('Stripe::Event', type: 'billing.credit_grant.created', data: double(object: event_object))
      handler_double = instance_double(Enterprise::Billing::V2::WebhookHandlerService, process: { success: true })

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Enterprise::Billing::HandleStripeEventService).to receive(:new)
      allow(Enterprise::Billing::V2::WebhookHandlerService).to receive(:new).with(account: account).and_return(handler_double)

      post '/enterprise/webhooks/stripe', headers: { 'Stripe-Signature': 'test' }, params: params

      expect(Enterprise::Billing::V2::WebhookHandlerService).to have_received(:new).with(account: account)
      expect(handler_double).to have_received(:process).with(event)
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
# rubocop:enable RSpec/VerifiedDoubles
