# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::ProviderFactory do
  describe '.get_provider' do
    context 'when PAYMENT_PROVIDER is set to stripe' do
      before { allow(ENV).to receive(:fetch).with('PAYMENT_PROVIDER', 'stripe').and_return('stripe') }

      it 'returns a Stripe provider instance' do
        provider = described_class.get_provider
        expect(provider).to be_a(Billing::Providers::Stripe)
      end
    end

    context 'when PAYMENT_PROVIDER is not set' do
      before { allow(ENV).to receive(:fetch).with('PAYMENT_PROVIDER', 'stripe').and_return('stripe') }

      it 'defaults to Stripe provider' do
        provider = described_class.get_provider
        expect(provider).to be_a(Billing::Providers::Stripe)
      end
    end

    context 'when PAYMENT_PROVIDER is set to an unsupported provider' do
      before { allow(ENV).to receive(:fetch).with('PAYMENT_PROVIDER', 'stripe').and_return('unsupported') }

      it 'raises an error' do
        expect { described_class.get_provider }
          .to raise_error(RuntimeError, 'Unsupported payment provider: Unsupported')
      end
    end

    context 'when provider class does not exist' do
      before { allow(ENV).to receive(:fetch).with('PAYMENT_PROVIDER', 'stripe').and_return('nonexistent') }

      it 'raises an error' do
        expect { described_class.get_provider }
          .to raise_error(RuntimeError, 'Unsupported payment provider: Nonexistent')
      end
    end
  end
end