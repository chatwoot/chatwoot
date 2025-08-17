# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::HandleEventService do
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
  let(:provider) { double('Billing::Providers::Stripe') }
  let(:service) { described_class.new(event_data) }

  before do
    allow(Billing::ProviderFactory).to receive(:get_provider).and_return(provider)
    allow(provider).to receive(:provider_name).and_return('stripe')
  end

  describe '#perform' do
    context 'when provider handles webhook successfully' do
      let(:provider_response) do
        {
          success: true,
          message: 'Subscription updated successfully'
        }
      end

      before do
        allow(provider).to receive(:handle_webhook).with(event_data).and_return(provider_response)
      end

      it 'delegates to the provider and returns success' do
        result = service.perform

        expect(provider).to have_received(:handle_webhook).with(event_data)
        expect(result[:success]).to be true
        expect(result[:message]).to eq('Subscription updated successfully')
      end

      it 'logs the successful processing' do
        expect(Rails.logger).to receive(:info).with('Processing webhook event: customer.subscription.updated via stripe provider')
        expect(Rails.logger).to receive(:info).with('Successfully processed webhook: Subscription updated successfully')

        service.perform
      end
    end

    context 'when provider fails to handle webhook' do
      let(:provider_response) do
        {
          success: false,
          error: 'Account not found'
        }
      end

      before do
        allow(provider).to receive(:handle_webhook).with(event_data).and_return(provider_response)
      end

      it 'returns the provider error' do
        result = service.perform

        expect(provider).to have_received(:handle_webhook).with(event_data)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Account not found')
      end

      it 'logs the failed processing' do
        expect(Rails.logger).to receive(:info).with('Processing webhook event: customer.subscription.updated via stripe provider')
        expect(Rails.logger).to receive(:error).with('Failed to process webhook: Account not found')

        service.perform
      end
    end

    context 'when provider raises an exception' do
      before do
        allow(provider).to receive(:handle_webhook).and_raise(StandardError, 'Provider error')
      end

      it 'handles the exception and returns error response' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to include('Webhook processing failed: Provider error')
        expect(result[:event_type]).to eq('customer.subscription.updated')
      end

      it 'logs the exception' do
        expect(Rails.logger).to receive(:info).with('Processing webhook event: customer.subscription.updated via stripe provider')
        expect(Rails.logger).to receive(:error).with('Error in HandleEventService: Provider error')

        service.perform
      end
    end

    context 'when provider factory fails' do
      before do
        allow(Billing::ProviderFactory).to receive(:get_provider).and_raise(StandardError, 'Unsupported provider')
      end

      it 'handles the factory error' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to include('Webhook processing failed: Unsupported provider')
      end
    end
  end
end