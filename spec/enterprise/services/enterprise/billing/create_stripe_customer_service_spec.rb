require 'rails_helper'

describe Enterprise::Billing::CreateStripeCustomerService do
  subject(:create_stripe_customer_service) { described_class }

  let(:account) { create(:account) }
  let!(:admin1) { create(:user, account: account, role: :administrator) }
  let(:admin2) { create(:user, account: account, role: :administrator) }
  let(:subscriptions_list) { double }

  describe '#perform' do
    before do
      create(
        :installation_config,
        { name: 'CHATWOOT_CLOUD_PLANS', value: [
          { 'name' => 'A Plan Name', 'product_id' => ['prod_hacker_random'], 'price_ids' => ['price_hacker_random'] }
        ] }
      )
    end

    it 'does not call stripe methods if customer id is present' do
      account.update!(custom_attributes: { stripe_customer_id: 'cus_random_number' })
      allow(subscriptions_list).to receive(:data).and_return([])
      allow(Stripe::Customer).to receive(:create)
      allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
      allow(Stripe::Subscription).to receive(:create)
        .and_return(
          {
            plan: { id: 'price_random_number', product: 'prod_random_number' },
            quantity: 2
          }.with_indifferent_access
        )

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
          plan_name: 'A Plan Name'
        }.with_indifferent_access
      )
    end

    it 'calls stripe methods to create a customer and updates the account' do
      customer = double
      allow(Stripe::Customer).to receive(:create).and_return(customer)
      allow(customer).to receive(:id).and_return('cus_random_number')
      allow(Stripe::Subscription)
        .to receive(:create)
        .and_return(
          {
            plan: { id: 'price_random_number', product: 'prod_random_number' },
            quantity: 2
          }.with_indifferent_access
        )

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
          plan_name: 'A Plan Name'
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
        allow(Stripe::Subscription).to receive(:create).and_return(
          {
            plan: { id: 'price_random_number', product: 'prod_random_number' },
            quantity: 2
          }.with_indifferent_access
        )

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
