# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::WebhookService, type: :service do
  let(:service) { described_class.new }
  let(:mock_provider) { instance_double(Billing::Providers::Stripe) }
  let(:payload) { '{"type": "subscription.updated", "id": "evt_123"}' }
  let(:signature) { 'test_signature' }
  let(:secret) { 'whsec_test_secret' }

  before do
    allow(Billing::ProviderFactory).to receive(:get_provider).and_return(mock_provider)
    allow(mock_provider).to receive(:provider_name).and_return('stripe')
  end

  describe '#initialize' do
    it 'initializes with a provider from the factory' do
      expect(Billing::ProviderFactory).to receive(:get_provider)
      described_class.new
    end
  end

  describe '#verify_signature' do
    context 'when signature verification succeeds' do
      before do
        allow(mock_provider).to receive(:verify_webhook_signature).and_return(true)
      end

      it 'returns true' do
        expect(service.verify_signature(payload, signature, secret)).to be true
      end

      it 'calls the provider with correct parameters' do
        expect(mock_provider).to receive(:verify_webhook_signature).with(payload, signature, secret)
        service.verify_signature(payload, signature, secret)
      end
    end

    context 'when signature verification fails' do
      before do
        allow(mock_provider).to receive(:verify_webhook_signature).and_return(false)
      end

      it 'returns false' do
        expect(service.verify_signature(payload, signature, secret)).to be false
      end
    end

    context 'when signature is blank' do
      it 'returns false for nil signature' do
        expect(service.verify_signature(payload, nil, secret)).to be false
      end

      it 'returns false for empty signature' do
        expect(service.verify_signature(payload, '', secret)).to be false
      end
    end

    context 'when secret is blank' do
      it 'returns false for nil secret' do
        expect(service.verify_signature(payload, signature, nil)).to be false
      end

      it 'returns false for empty secret' do
        expect(service.verify_signature(payload, signature, '')).to be false
      end
    end

    context 'when provider raises an error' do
      before do
        allow(mock_provider).to receive(:verify_webhook_signature).and_raise(StandardError, 'Verification failed')
        allow(Rails.logger).to receive(:error)
      end

      it 'returns false' do
        expect(service.verify_signature(payload, signature, secret)).to be false
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Webhook signature verification failed: Verification failed')
        service.verify_signature(payload, signature, secret)
      end
    end
  end

  describe '#process_event' do
    let(:event_data) { { 'type' => 'subscription.updated', 'id' => 'evt_123' } }

    context 'when event processing succeeds' do
      let(:success_result) { { success: true, message: 'Event processed successfully' } }

      before do
        allow(mock_provider).to receive(:handle_webhook).and_return(success_result)
        allow(Rails.logger).to receive(:info)
      end

      it 'returns success result' do
        expect(service.process_event(event_data)).to eq(success_result)
      end

      it 'calls the provider with event data' do
        expect(mock_provider).to receive(:handle_webhook).with(event_data)
        service.process_event(event_data)
      end

      it 'logs the processing start' do
        expect(Rails.logger).to receive(:info).with('Processing webhook via stripe provider: subscription.updated')
        service.process_event(event_data)
      end

      it 'logs the success' do
        expect(Rails.logger).to receive(:info).with('Webhook processed successfully: Event processed successfully')
        service.process_event(event_data)
      end
    end

    context 'when event processing fails' do
      let(:failure_result) { { success: false, error: 'Processing failed' } }

      before do
        allow(mock_provider).to receive(:handle_webhook).and_return(failure_result)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns failure result' do
        expect(service.process_event(event_data)).to eq(failure_result)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Webhook processing failed: Processing failed')
        service.process_event(event_data)
      end
    end

    context 'when provider raises an error' do
      before do
        allow(mock_provider).to receive(:handle_webhook).and_raise(StandardError, 'Provider error')
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns error result' do
        result = service.process_event(event_data)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Webhook processing failed: Provider error')
        expect(result[:provider]).to eq('stripe')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Error in WebhookService: Provider error')
        service.process_event(event_data)
      end
    end
  end

  describe '#provider_name' do
    it 'returns the provider name' do
      expect(service.provider_name).to eq('stripe')
    end
  end

  describe '#webhook_secret' do
    context 'with stripe provider' do
      before do
        allow(ENV).to receive(:fetch).with('STRIPE_WEBHOOK_SECRET', nil).and_return('stripe_secret')
      end

      it 'returns the stripe webhook secret' do
        expect(service.webhook_secret).to eq('stripe_secret')
      end
    end

    context 'with paypal provider' do
      before do
        allow(mock_provider).to receive(:provider_name).and_return('paypal')
        allow(ENV).to receive(:fetch).with('PAYPAL_WEBHOOK_SECRET', nil).and_return('paypal_secret')
      end

      it 'returns the paypal webhook secret' do
        expect(service.webhook_secret).to eq('paypal_secret')
      end
    end

    context 'with paddle provider' do
      before do
        allow(mock_provider).to receive(:provider_name).and_return('paddle')
        allow(ENV).to receive(:fetch).with('PADDLE_WEBHOOK_SECRET', nil).and_return('paddle_secret')
      end

      it 'returns the paddle webhook secret' do
        expect(service.webhook_secret).to eq('paddle_secret')
      end
    end

    context 'with unknown provider' do
      before do
        allow(mock_provider).to receive(:provider_name).and_return('unknown')
        allow(Rails.logger).to receive(:warn)
      end

      it 'returns nil' do
        expect(service.webhook_secret).to be_nil
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with('No webhook secret configured for provider: unknown')
        service.webhook_secret
      end
    end
  end

  describe '#configured?' do
    context 'when webhook secret is present' do
      before do
        allow(service).to receive(:webhook_secret).and_return('secret')
      end

      it 'returns true' do
        expect(service.configured?).to be true
      end
    end

    context 'when webhook secret is blank' do
      before do
        allow(service).to receive(:webhook_secret).and_return(nil)
      end

      it 'returns false' do
        expect(service.configured?).to be false
      end
    end
  end
end