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
      let(:period_end) { 1_790_845_600 }
      let(:base) { { cancel_at: nil, cancel_at_period_end: false, items: { data: [{ current_period_end: period_end }] } } }
      let(:subscription_response) { Struct.new(:data).new([sub_1, sub_2, sub_3]) }
      let(:sub_1) { Stripe::Subscription.construct_from(base.merge(id: 'sub_1')) }
      # Flexible billing schedules the cancellation on cancel_at, classic billing on cancel_at_period_end.
      let(:sub_2) { Stripe::Subscription.construct_from(base.merge(id: 'sub_2', cancel_at: period_end)) }
      let(:sub_3) { Stripe::Subscription.construct_from(base.merge(id: 'sub_3', cancel_at_period_end: true)) }

      it 'schedules cancellation at the period end, skipping the ones already cancelling' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        allow(Stripe::Subscription).to receive(:list).and_return(subscription_response)
        allow(Stripe::Subscription).to receive(:update)

        service.perform

        expect(Stripe::Subscription).to have_received(:list).with(customer: 'cus_123', status: 'active', limit: 100)
        expect(Stripe::Subscription).to have_received(:update).with('sub_1', cancel_at: period_end).once
        expect(Stripe::Subscription).to have_received(:update).once
      end
    end
  end
end
