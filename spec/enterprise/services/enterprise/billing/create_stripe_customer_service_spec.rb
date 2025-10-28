require 'rails_helper'

describe Enterprise::Billing::CreateStripeCustomerService do
  subject(:create_stripe_customer_service) { described_class }

  let(:account) { create(:account) }
  let!(:admin1) { create(:user, account: account, role: :administrator) }

  describe '#perform' do
    context 'when customer does not exist' do
      it 'creates a stripe customer and saves the customer_id' do
        customer = double
        allow(Stripe::Customer).to receive(:create).and_return(customer)
        allow(customer).to receive(:id).and_return('cus_random_number')

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).to have_received(:create).with({ name: account.name, email: admin1.email })
        expect(account.reload.custom_attributes).to eq(
          {
            stripe_customer_id: 'cus_random_number'
          }.with_indifferent_access
        )
      end
    end

    context 'when customer already exists' do
      before do
        account.update!(custom_attributes: { stripe_customer_id: 'cus_existing_customer' })
      end

      it 'does not create a new customer' do
        allow(Stripe::Customer).to receive(:create)
        # Stub the subscription check to return no subscriptions
        subscriptions_response = OpenStruct.new(data: [])
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_response)

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).not_to have_received(:create)
        expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_existing_customer')
      end
    end

    context 'with V2 billing enabled' do
      let(:cloud_plans_config) do
        create(:installation_config,
               name: 'CHATWOOT_CLOUD_PLANS',
               value: [
                 {
                   'name' => 'Startup',
                   'price_ids' => ['price_startup_123'],
                   'default_quantity' => 2
                 }
               ])
      end

      let(:hacker_plan_config) do
        create(:installation_config,
               name: 'STRIPE_HACKER_PLAN_ID',
               value: 'bpp_hacker_123')
      end

      before do
        # Setup configs
        cloud_plans_config
        hacker_plan_config
        # Enable V2 billing
        allow(ENV).to receive(:fetch).with('STRIPE_BILLING_V2_ENABLED', 'false').and_return('true')
      end

      it 'creates a stripe customer and sets up V2 billing' do
        customer = double
        allow(Stripe::Customer).to receive(:create).and_return(customer)
        allow(customer).to receive(:id).and_return('cus_random_number')

        # Mock the plan feature manager
        service = create_stripe_customer_service.new(account: account)
        allow(service).to receive(:enable_plan_specific_features)

        service.perform

        expect(Stripe::Customer).to have_received(:create).with({ name: account.name, email: admin1.email })
        expect(account.reload.custom_attributes).to include(
          'stripe_customer_id' => 'cus_random_number',
          'stripe_pricing_plan_id' => 'bpp_hacker_123',
          'plan_name' => 'Hacker',
          'subscribed_quantity' => 2
        )
        expect(service).to have_received(:enable_plan_specific_features).with('Startup')
      end

      it 'does not create new customer when customer already exists with V2' do
        account.update!(custom_attributes: { stripe_customer_id: 'cus_existing_v2' })

        allow(Stripe::Customer).to receive(:create)
        # Stub the subscription check to return no subscriptions
        subscriptions_response = OpenStruct.new(data: [])
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_response)

        # Mock the plan feature manager
        service = create_stripe_customer_service.new(account: account)
        allow(service).to receive(:enable_plan_specific_features)

        service.perform

        expect(Stripe::Customer).not_to have_received(:create)
        expect(account.reload.custom_attributes).to include(
          'stripe_customer_id' => 'cus_existing_v2',
          'stripe_pricing_plan_id' => 'bpp_hacker_123',
          'plan_name' => 'Hacker',
          'subscribed_quantity' => 2
        )
      end

      it 'skips setup when active subscription exists' do
        account.update!(custom_attributes: { stripe_customer_id: 'cus_existing_v2' })

        allow(Stripe::Customer).to receive(:create)
        # Stub the subscription check to return active subscription
        subscription_data = OpenStruct.new(id: 'sub_123')
        subscriptions_response = OpenStruct.new(data: [subscription_data])
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_response)

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).not_to have_received(:create)
        expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_existing_v2')
      end
    end

    context 'with V1 billing (traditional subscription)' do
      let(:cloud_plans_config) do
        create(:installation_config,
               name: 'CHATWOOT_CLOUD_PLANS',
               value: [
                 {
                   'name' => 'Startup',
                   'price_ids' => ['price_startup_123'],
                   'default_quantity' => 2
                 }
               ])
      end

      before do
        cloud_plans_config
        allow(ENV).to receive(:fetch).with('STRIPE_BILLING_V2_ENABLED', 'false').and_return('false')
      end

      it 'creates a stripe customer and traditional subscription' do
        customer = double
        allow(Stripe::Customer).to receive(:create).and_return(customer)
        allow(customer).to receive(:id).and_return('cus_random_number')

        subscription = {
          'plan' => { 'id' => 'price_startup_123', 'product' => 'prod_startup' },
          'quantity' => 2
        }
        allow(Stripe::Subscription).to receive(:create).and_return(subscription)

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).to have_received(:create).with({ name: account.name, email: admin1.email })
        expect(Stripe::Subscription).to have_received(:create)
        expect(account.reload.custom_attributes).to include(
          'stripe_customer_id' => 'cus_random_number',
          'stripe_price_id' => 'price_startup_123',
          'stripe_product_id' => 'prod_startup',
          'plan_name' => 'Startup',
          'subscribed_quantity' => 2
        )
      end
    end
  end
end
