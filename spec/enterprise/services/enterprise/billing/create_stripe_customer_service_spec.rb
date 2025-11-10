require 'rails_helper'

describe Enterprise::Billing::CreateStripeCustomerService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:stripe_customer_double) { instance_double(Stripe::Customer, id: 'cus_new') }
  let(:subscriptions_list) { Stripe::ListObject.construct_from({ data: [] }) }
  let(:hacker_plan_id) { 'price_hacker_random' }

  before do
    create(
      :installation_config,
      name: 'CHATWOOT_CLOUD_PLANS',
      value: [
        {
          'name' => 'Hacker',
          'limits' => {
            'captain_responses_monthly' => 5,
            'captain_responses_topup' => 0
          }
        }
      ]
    )

    create(:installation_config, name: 'STRIPE_HACKER_PLAN_ID', value: hacker_plan_id)
  end

  describe '#perform' do
    context 'when account already has an active subscription' do
      before do
        account.update!(custom_attributes: { stripe_customer_id: 'cus_existing' })
        allow(Stripe::Subscription).to receive(:list)
          .and_return(Stripe::ListObject.construct_from({ data: ['subscription'] }))
      end

      it 'returns without modifying the account or contacting Stripe' do
        expect(Stripe::Customer).not_to receive(:create)

        expect { service.perform }.not_to(change { account.reload.custom_attributes })
      end
    end

    context 'when v2 billing configuration is missing' do
      before do
        InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID').destroy!
      end

      it 'raises an informative error' do
        expect { service.perform }.to raise_error(
          StandardError,
          'V2 billing configuration is required. Please configure STRIPE_HACKER_PLAN_ID.'
        )
      end
    end

    context 'when account needs to be upgraded to v2 billing' do
      context 'when stripe customer already exists' do
        before do
          account.update!(custom_attributes: { stripe_customer_id: 'cus_existing' })
          allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
          allow(Stripe::Customer).to receive(:create)
        end

        it 'does not create a new customer but updates custom attributes for v2 billing' do
          service.perform

          expect(Stripe::Customer).not_to have_received(:create)

          expect(account.reload.custom_attributes).to include(
            'stripe_customer_id' => 'cus_existing',
            'stripe_pricing_plan_id' => hacker_plan_id,
            'plan_name' => 'Hacker',
            'subscribed_quantity' => described_class::DEFAULT_QUANTITY,
            'stripe_billing_version' => 2
          )
        end
      end

      context 'when stripe customer does not exist' do
        before do
          allow(Stripe::Customer).to receive(:create).and_return(stripe_customer_double)
        end

        it 'creates a stripe customer and updates the account with v2 billing attributes' do
          service.perform

          expect(Stripe::Customer).to have_received(:create).with({ name: account.name, email: admin.email })

          expect(account.reload.custom_attributes).to include(
            'stripe_customer_id' => 'cus_new',
            'stripe_pricing_plan_id' => hacker_plan_id,
            'plan_name' => 'Hacker',
            'subscribed_quantity' => described_class::DEFAULT_QUANTITY,
            'stripe_billing_version' => 2
          )
        end
      end
    end
  end
end
