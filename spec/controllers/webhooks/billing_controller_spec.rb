# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::BillingController', type: :request do
  let(:webhook_service) { instance_double(Billing::WebhookService) }
  let(:event_data) do
    {
      'type' => 'customer.subscription.updated',
      'data' => {
        'object' => {
          'id' => 'sub_123',
          'customer' => 'cus_123'
        }
      }
    }
  end
  let(:payload) { event_data.to_json }
  let(:signature) { 'stripe_signature_123' }

  before do
    allow(Billing::WebhookService).to receive(:new).and_return(webhook_service)
    allow(webhook_service).to receive(:provider_name).and_return('stripe')
    allow(webhook_service).to receive(:webhook_secret).and_return('webhook_secret')
  end

  describe 'POST /webhooks/billing/process_event' do
    context 'with valid signature and successful processing' do
      let(:service_result) do
        {
          success: true,
          message: 'Subscription updated successfully'
        }
      end

      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(true)
        allow(webhook_service).to receive(:process_event).and_return(service_result)
      end

      it 'processes the webhook successfully' do
        # Mock request.body.read to return our payload
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['received']).to be true
        expect(json_response['message']).to eq('Subscription updated successfully')
      end

      it 'verifies the webhook signature' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(webhook_service).to have_received(:verify_signature)
          .with(payload, signature, 'webhook_secret')
      end

      it 'processes the event through webhook service' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(webhook_service).to have_received(:process_event).with(event_data)
      end
    end

    context 'with invalid signature' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(false)
      end

      it 'returns bad request for invalid signature' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid signature')
      end

      it 'logs signature verification failure' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        expect(Rails.logger).to receive(:error)
          .with('Stripe webhook signature verification failed')

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }
      end
    end

    context 'with webhook not configured' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(false)
      end

      it 'returns internal server error for unconfigured webhook' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Webhook not configured')
      end
    end

    context 'with missing signature' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(false)
      end

      it 'returns bad request for missing signature' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid signature')
      end
    end

    context 'with invalid JSON payload' do
      let(:invalid_payload) { 'invalid json' }

      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(true)
      end

      it 'returns bad request for invalid JSON' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(invalid_payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid JSON')
      end

      it 'logs JSON parsing error' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(invalid_payload)

        expect(Rails.logger).to receive(:error)
          .with(/Invalid JSON in webhook/)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }
      end
    end

    context 'with webhook processing failure' do
      let(:service_result) do
        {
          success: false,
          error: 'Account not found'
        }
      end

      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(true)
        allow(webhook_service).to receive(:process_event).and_return(service_result)
      end

      it 'returns unprocessable entity for processing failure' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Account not found')
      end
    end

    context 'with unexpected error' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature)
          .and_raise(StandardError, 'Unexpected error')
      end

      it 'returns internal server error' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Webhook processing failed')
      end

      it 'logs unexpected error' do
        allow_any_instance_of(ActionDispatch::Request).to receive_message_chain(:body, :read).and_return(payload)

        expect(Rails.logger).to receive(:error)
          .with('Error processing webhook: Unexpected error')

        post '/webhooks/billing/process_event',
             headers: { 'Stripe-Signature' => signature, 'Content-Type' => 'application/json' }
      end
    end
  end

  describe 'GET /webhooks/billing/health' do
    before do
      allow(webhook_service).to receive(:configured?).and_return(true)
    end

    it 'returns health status with provider information' do
      get '/webhooks/billing/health'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('ok')
      expect(json_response['provider']).to eq('stripe')
      expect(json_response['webhook_endpoint']).to eq('active')
      expect(json_response['configured']).to be true
      expect(json_response['timestamp']).to be_present
    end
  end
end