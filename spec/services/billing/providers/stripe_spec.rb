# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::Providers::Stripe do
  let(:provider) { described_class.new }
  let(:account) { create(:account) }
  let!(:user) { create(:user, account: account, email: 'test@example.com') }

  describe '#provider_name' do
    it 'returns stripe' do
      expect(provider.provider_name).to eq('stripe')
    end
  end

  describe '#create_customer' do
    let(:stripe_customer) { double('Stripe::Customer', id: 'cus_123') }

    before do
      allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
    end

    it 'creates a customer in Stripe' do
      result = provider.create_customer(account, 'starter')

      expect(Stripe::Customer).to have_received(:create).with(
        email: 'test@example.com',
        name: account.name,
        metadata: {
          account_id: account.id,
          plan: 'starter'
        }
      )
      expect(result).to eq(stripe_customer)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Customer).to receive(:create).and_raise(Stripe::StripeError.new('API error'))

      expect { provider.create_customer(account, 'starter') }
        .to raise_error(StandardError, /Failed to create customer/)
    end
  end

  describe '#create_subscription' do
    let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_123') }

    before do
      allow(Stripe::Subscription).to receive(:create).and_return(stripe_subscription)
    end

    it 'creates a subscription in Stripe' do
      result = provider.create_subscription('cus_123', 'price_123', 1)

      expect(Stripe::Subscription).to have_received(:create).with(
        customer: 'cus_123',
        items: [{ price: 'price_123', quantity: 1 }], # Always 1 for billing
        metadata: {
          plan_id: 'price_123',
          quantity: 1 # Metadata reflects the passed quantity
        }
      )
      expect(result).to eq(stripe_subscription)
    end

    it 'returns nil for free trial plans' do
      result = provider.create_subscription('cus_123', nil, 1)
      expect(result).to be_nil
      expect(Stripe::Subscription).not_to have_received(:create)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Subscription).to receive(:create).and_raise(Stripe::StripeError.new('API error'))

      expect { provider.create_subscription('cus_123', 'price_123', 1) }
        .to raise_error(StandardError, /Failed to create subscription/)
    end
  end

  describe '#create_portal_session' do
    let(:portal_session) { double('Stripe::BillingPortal::Session', id: 'bps_123', url: 'https://billing.stripe.com/session') }

    before do
      allow(Stripe::BillingPortal::Session).to receive(:create).and_return(portal_session)
    end

    it 'creates a portal session in Stripe' do
      result = provider.create_portal_session('cus_123', 'https://example.com/return')

      expect(Stripe::BillingPortal::Session).to have_received(:create).with(
        customer: 'cus_123',
        return_url: 'https://example.com/return'
      )
      expect(result).to eq(portal_session)
    end

    it 'handles Stripe errors' do
      allow(Stripe::BillingPortal::Session).to receive(:create).and_raise(Stripe::StripeError.new('API error'))

      expect { provider.create_portal_session('cus_123', 'https://example.com/return') }
        .to raise_error(StandardError, /Failed to create portal session/)
    end
  end

  describe '#verify_webhook_signature' do
    it 'returns true for valid signatures' do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(double('Event'))

      result = provider.verify_webhook_signature('payload', 'signature', 'secret')

      expect(result).to be true
      expect(Stripe::Webhook).to have_received(:construct_event).with('payload', 'signature', 'secret')
    end

    it 'returns false for invalid signatures' do
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new('Invalid signature', 'signature'))

      result = provider.verify_webhook_signature('payload', 'invalid_signature', 'secret')

      expect(result).to be false
    end
  end

  describe '#get_customer' do
    let(:stripe_customer) { double('Stripe::Customer', id: 'cus_123') }

    before do
      allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
    end

    it 'retrieves a customer from Stripe' do
      result = provider.get_customer('cus_123')

      expect(Stripe::Customer).to have_received(:retrieve).with('cus_123')
      expect(result).to eq(stripe_customer)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Customer).to receive(:retrieve).and_raise(Stripe::StripeError.new('Not found'))

      expect { provider.get_customer('cus_123') }
        .to raise_error(StandardError, /Failed to retrieve customer/)
    end
  end

  describe '#get_subscription' do
    let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_123') }

    before do
      allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_subscription)
    end

    it 'retrieves a subscription from Stripe' do
      result = provider.get_subscription('sub_123')

      expect(Stripe::Subscription).to have_received(:retrieve).with('sub_123')
      expect(result).to eq(stripe_subscription)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Subscription).to receive(:retrieve).and_raise(Stripe::StripeError.new('Not found'))

      expect { provider.get_subscription('sub_123') }
        .to raise_error(StandardError, /Failed to retrieve subscription/)
    end
  end

  describe '#cancel_subscription' do
    let(:cancelled_subscription) { double('Stripe::Subscription', id: 'sub_123', status: 'canceled') }

    before do
      allow(Stripe::Subscription).to receive(:cancel).and_return(cancelled_subscription)
    end

    it 'cancels a subscription in Stripe' do
      result = provider.cancel_subscription('sub_123')

      expect(Stripe::Subscription).to have_received(:cancel).with('sub_123')
      expect(result).to eq(cancelled_subscription)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Subscription).to receive(:cancel).and_raise(Stripe::StripeError.new('Cannot cancel'))

      expect { provider.cancel_subscription('sub_123') }
        .to raise_error(StandardError, /Failed to cancel subscription/)
    end
  end

  describe '#update_subscription' do
    let(:existing_subscription) do
      double('Stripe::Subscription',
             items: double('Items', data: [double('Item', id: 'si_123')]))
    end
    let(:updated_subscription) { double('Stripe::Subscription', id: 'sub_123') }

    before do
      allow(provider).to receive(:get_subscription).and_return(existing_subscription)
      allow(Stripe::Subscription).to receive(:update).and_return(updated_subscription)
    end

    it 'updates a subscription with new plan' do
      result = provider.update_subscription('sub_123', { plan_id: 'price_456' })

      expect(Stripe::Subscription).to have_received(:update).with('sub_123', {
                                                                    items: [{ id: 'si_123', price: 'price_456' }]
                                                                  })
      expect(result).to eq(updated_subscription)
    end

    it 'updates a subscription with new quantity' do
      result = provider.update_subscription('sub_123', { quantity: 5 })

      expect(Stripe::Subscription).to have_received(:update).with('sub_123', {
                                                                    quantity: 5
                                                                  })
      expect(result).to eq(updated_subscription)
    end

    it 'handles Stripe errors' do
      allow(Stripe::Subscription).to receive(:update).and_raise(Stripe::StripeError.new('Update failed'))

      expect { provider.update_subscription('sub_123', { quantity: 5 }) }
        .to raise_error(StandardError, /Failed to update subscription/)
    end
  end

  describe '#handle_webhook' do
    let(:webhook_account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123' }) }

    before do
      webhook_account # Ensure account exists
    end

    context 'checkout session completed event' do
      let(:stripe_subscription) do
        {
          'status' => 'active',
          'customer' => 'cus_123',
          'current_period_end' => 1_234_567_890,
          'items' => { 'data' => [{ 'quantity' => 1 }] },
          'metadata' => { 'plan_name' => 'starter' }
        }
      end

      let(:event_data) do
        {
          'type' => 'checkout.session.completed',
          'data' => {
            'object' => {
              'customer' => 'cus_123',
              'subscription' => 'sub_123',
              'metadata' => {
                'account_id' => webhook_account.id.to_s,
                'plan_name' => 'starter'
              }
            }
          }
        }
      end

      before do
        allow(provider).to receive(:get_subscription).with('sub_123').and_return(stripe_subscription)
      end

      it 'handles checkout session completed events' do
        result = provider.handle_webhook(event_data)

        expect(result[:success]).to be true
        expect(result[:message]).to include('Checkout session completed and account updated successfully')

        webhook_account.reload
        expect(webhook_account.custom_attributes['plan_name']).to eq('starter')
        expect(webhook_account.custom_attributes['subscription_status']).to eq('active')
        expect(webhook_account.custom_attributes['stripe_customer_id']).to eq('cus_123')
      end

      it 'handles missing account' do
        event_data['data']['object']['metadata']['account_id'] = '999999'

        result = provider.handle_webhook(event_data)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Account not found from checkout session metadata')
      end
    end

    context 'subscription created event' do
      let(:event_data) do
        {
          'type' => 'customer.subscription.created',
          'data' => {
            'object' => {
              'customer' => 'cus_123',
              'status' => 'active',
              'current_period_end' => 1_234_567_890,
              'items' => { 'data' => [{ 'quantity' => 1 }] },
              'metadata' => {
                'account_id' => webhook_account.id.to_s,
                'plan_name' => 'starter'
              }
            }
          }
        }
      end

      it 'handles subscription created events' do
        result = provider.handle_webhook(event_data)

        expect(result[:success]).to be true
        expect(result[:message]).to include('created and account updated')
      end
    end

    context 'unhandled event type' do
      let(:event_data) do
        {
          'type' => 'unknown.event',
          'data' => { 'object' => {} }
        }
      end

      it 'acknowledges but does not process unknown events' do
        result = provider.handle_webhook(event_data)

        expect(result[:success]).to be true
        expect(result[:message]).to include('acknowledged but not processed')
      end
    end
  end
end