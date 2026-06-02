require 'rails_helper'

RSpec.describe Enterprise::Billing::CancelCloudSubscriptionsService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account, custom_attributes: custom_attributes) }
  let(:custom_attributes) { { 'stripe_customer_id' => 'cus_123' } }

  describe '#perform' do
    context 'when deployment is not cloud' do
      it 'does not call stripe subscriptions api' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        allow(Stripe::Subscription).to receive(:list)

        service.perform

        expect(Stripe::Subscription).not_to have_received(:list)
      end
    end

    context 'when stripe customer id is missing' do
      let(:custom_attributes) { {} }

      it 'does not call stripe subscriptions api' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        allow(Stripe::Subscription).to receive(:list)

        service.perform

        expect(Stripe::Subscription).not_to have_received(:list)
      end
    end

    context 'when account is cloud with active subscriptions' do
      let(:subscription_response) { Struct.new(:data).new([sub_1, sub_2]) }
      let(:sub_1) { instance_double(Stripe::Subscription, id: 'sub_1', cancel_at_period_end: false) }
      let(:sub_2) { instance_double(Stripe::Subscription, id: 'sub_2', cancel_at_period_end: true) }

      it 'marks only active subscriptions that are not yet set to cancel at period end' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        allow(Stripe::Subscription).to receive(:list).and_return(subscription_response)
        allow(Stripe::Subscription).to receive(:update)

        service.perform

        expect(Stripe::Subscription).to have_received(:list).with(customer: 'cus_123', status: 'active', limit: 100)
        expect(Stripe::Subscription).to have_received(:update).with('sub_1', cancel_at_period_end: true).once
      end
    end
  end
end
