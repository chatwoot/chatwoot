# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::BillingController, type: :controller do
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

  describe 'POST #process_event' do
    before do
      request.headers['Stripe-Signature'] = signature
      allow(request.body).to receive(:read).and_return(payload)
    end

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
        post :process_event

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['received']).to be true
        expect(json_response['message']).to eq('Subscription updated successfully')
      end

      it 'verifies the webhook signature' do
        post :process_event

        expect(webhook_service).to have_received(:verify_signature)
          .with(payload, signature, 'webhook_secret')
      end

      it 'processes the event through webhook service' do
        post :process_event

        expect(webhook_service).to have_received(:process_event).with(event_data)
      end
    end

    context 'with invalid signature' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(false)
      end

      it 'returns bad request for invalid signature' do
        post :process_event

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid signature')
      end

      it 'logs signature verification failure' do
        expect(Rails.logger).to receive(:error)
          .with('Stripe webhook signature verification failed')

        post :process_event
      end
    end

    context 'with webhook not configured' do
      before do
        allow(webhook_service).to receive(:configured?).and_return(false)
      end

      it 'returns internal server error for unconfigured webhook' do
        post :process_event

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Webhook not configured')
      end
    end

    context 'with missing signature' do
      before do
        request.headers.delete('Stripe-Signature')
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(false)
      end

      it 'returns bad request for missing signature' do
        post :process_event

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid signature')
      end
    end

    context 'with invalid JSON payload' do
      let(:payload) { 'invalid json' }

      before do
        allow(webhook_service).to receive(:configured?).and_return(true)
        allow(webhook_service).to receive(:verify_signature).and_return(true)
      end

      it 'returns bad request for invalid JSON' do
        post :process_event

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid JSON')
      end

      it 'logs JSON parsing error' do
        expect(Rails.logger).to receive(:error)
          .with(/Invalid JSON in webhook/)

        post :process_event
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
        post :process_event

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
        post :process_event

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Webhook processing failed')
      end

      it 'logs unexpected error' do
        expect(Rails.logger).to receive(:error)
          .with('Error processing webhook: Unexpected error')

        post :process_event
      end
    end
  end

  describe 'GET #health' do
    before do
      allow(webhook_service).to receive(:configured?).and_return(true)
    end

    it 'returns health status with provider information' do
      get :health

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