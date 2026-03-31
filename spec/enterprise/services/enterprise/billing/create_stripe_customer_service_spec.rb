require 'rails_helper'

describe Enterprise::Billing::CreateStripeCustomerService do
  subject(:create_stripe_customer_service) { described_class }

  let(:account) { create(:account) }
  let!(:admin1) { create(:user, account: account, role: :administrator) }
  let(:admin2) { create(:user, account: account, role: :administrator) }
  let(:subscriptions_list) { double }
  let(:current_period_end) { 1_686_567_520 }
  let(:subscription_ends_on) { Time.zone.at(current_period_end).as_json }
  let(:created_subscription) do
    {
      plan: { id: 'price_random_number', product: 'prod_random_number' },
      quantity: 2,
      status: 'active',
      current_period_end: current_period_end
    }.with_indifferent_access
  end

  describe '#perform' do
    before do
      create(
        :installation_config,
        { name: 'CHATWOOT_CLOUD_PLANS', value: [
          { 'name' => 'A Plan Name', 'product_id' => ['prod_hacker_random'], 'price_ids' => ['price_hacker_random'] }
        ] }
      )
    end

    it 'preserves unrelated custom attributes, clears is_creating_customer, and reconciles default-plan features' do
      account.update!(
        custom_attributes: {
          'is_creating_customer' => true,
          'onboarding_source' => 'billing_page',
          'subscription_status' => 'past_due',
          'subscription_ends_on' => 1.day.ago
        }
      )
      account.enable_features!(:help_center)

      customer = double
      allow(Stripe::Customer).to receive(:create).and_return(customer)
      allow(customer).to receive(:id).and_return('cus_random_number')
      allow(Stripe::Subscription).to receive(:create).and_return(created_subscription)

      create_stripe_customer_service.new(account: account).perform

      expect(account.reload.custom_attributes).to include(
        'stripe_customer_id' => customer.id,
        'stripe_price_id' => 'price_random_number',
        'stripe_product_id' => 'prod_random_number',
        'subscribed_quantity' => 2,
        'plan_name' => 'A Plan Name',
        'onboarding_source' => 'billing_page',
        'subscription_status' => 'active',
        'subscription_ends_on' => subscription_ends_on
      )
      expect(account.custom_attributes).not_to have_key('is_creating_customer')
      expect(account).not_to be_feature_enabled('help_center')
    end

    it 'does not call stripe methods if customer id is present' do
      account.update!(custom_attributes: { stripe_customer_id: 'cus_random_number' })
      allow(subscriptions_list).to receive(:data).and_return([])
      allow(Stripe::Customer).to receive(:create)
      allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
      allow(Stripe::Subscription).to receive(:create).and_return(created_subscription)

      create_stripe_customer_service.new(account: account).perform

      expect(Stripe::Customer).not_to have_received(:create)
      expect(Stripe::Subscription)
        .to have_received(:create)
        .with({ customer: 'cus_random_number', items: [{ price: 'price_hacker_random', quantity: 2 }] })

      expect(account.reload.custom_attributes).to eq(
        {
          stripe_customer_id: 'cus_random_number',
          stripe_price_id: 'price_random_number',
          stripe_product_id: 'prod_random_number',
          subscribed_quantity: 2,
          plan_name: 'A Plan Name',
          subscription_status: 'active',
          subscription_ends_on: subscription_ends_on
        }.with_indifferent_access
      )
    end

    it 'calls stripe methods to create a customer and updates the account' do
      customer = double
      allow(Stripe::Customer).to receive(:create).and_return(customer)
      allow(customer).to receive(:id).and_return('cus_random_number')
      allow(Stripe::Subscription).to receive(:create).and_return(created_subscription)

      create_stripe_customer_service.new(account: account).perform

      expect(Stripe::Customer).to have_received(:create).with({ name: account.name, email: admin1.email })
      expect(Stripe::Subscription)
        .to have_received(:create)
        .with({ customer: customer.id, items: [{ price: 'price_hacker_random', quantity: 2 }] })

      expect(account.reload.custom_attributes).to eq(
        {
          stripe_customer_id: customer.id,
          stripe_price_id: 'price_random_number',
          stripe_product_id: 'prod_random_number',
          subscribed_quantity: 2,
          plan_name: 'A Plan Name',
          subscription_status: 'active',
          subscription_ends_on: subscription_ends_on
        }.with_indifferent_access
      )
    end
  end

  describe 'when checking for existing subscriptions' do
    before do
      create(
        :installation_config,
        { name: 'CHATWOOT_CLOUD_PLANS', value: [
          { 'name' => 'A Plan Name', 'product_id' => ['prod_hacker_random'], 'price_ids' => ['price_hacker_random'] }
        ] }
      )
    end

    context 'when account has no stripe_customer_id' do
      it 'creates a new subscription' do
        customer = double
        allow(Stripe::Customer).to receive(:create).and_return(customer)
        allow(customer).to receive(:id).and_return('cus_random_number')
        allow(Stripe::Subscription).to receive(:create).and_return(created_subscription)

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).to have_received(:create)
        expect(Stripe::Subscription).to have_received(:create)
      end
    end

    context 'when account has stripe_customer_id' do
      let(:stripe_customer_id) { 'cus_random_number' }

      before do
        account.update!(custom_attributes: { stripe_customer_id: stripe_customer_id })
      end

      context 'when customer has active subscriptions' do
        before do
          allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
          allow(subscriptions_list).to receive(:data).and_return(['subscription'])
          allow(Stripe::Subscription).to receive(:create)
        end

        it 'does not create a new subscription' do
          create_stripe_customer_service.new(account: account).perform

          expect(Stripe::Subscription).not_to have_received(:create)
          expect(Stripe::Subscription).to have_received(:list).with(
            {
              customer: stripe_customer_id,
              status: 'active',
              limit: 1
            }
          )
        end
      end
    end
  end
end
