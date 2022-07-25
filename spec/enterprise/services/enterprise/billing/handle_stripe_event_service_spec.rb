require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  subject(:stripe_event_service) { described_class }

  let(:event) { double }
  let(:data) { double }
  let(:subscription) { double }
  let!(:account) { create(:account, custom_attributes: { stripe_customer_id: 'cus_123' }) }

  before do
    allow(event).to receive(:data).and_return(data)
    allow(data).to receive(:object).and_return(subscription)
    allow(subscription).to receive(:[]).with('plan')
                                       .and_return({
                                                     'id' => 'test', 'product' => 'plan_id', 'name' => 'plan_name'
                                                   })
    allow(subscription).to receive(:[]).with('quantity').and_return('10')
    allow(subscription).to receive(:customer).and_return('cus_123')
    create(:installation_config, {
             name: 'CHATWOOT_CLOUD_PLANS',
             value: [
               {
                 'name' => 'Hacker',
                 'product_id' => ['plan_id'],
                 'price_ids' => ['price_1']
               },
               {
                 'name' => 'Startups',
                 'product_id' => ['plan_id_2'],
                 'price_ids' => ['price_2']
               }
             ]
           })
  end

  describe '#perform' do
    it 'handle customer.subscription.updated' do
      allow(event).to receive(:type).and_return('customer.subscription.updated')
      allow(subscription).to receive(:customer).and_return('cus_123')
      stripe_event_service.new.perform(event: event)
      expect(account.reload.custom_attributes).to eq({
                                                       'stripe_customer_id' => 'cus_123',
                                                       'stripe_price_id' => 'test',
                                                       'stripe_product_id' => 'plan_id',
                                                       'plan_name' => 'Hacker',
                                                       'subscribed_quantity' => '10'
                                                     })
    end

    it 'handles customer.subscription.deleted' do
      stripe_customer_service = double
      allow(event).to receive(:type).and_return('customer.subscription.deleted')
      allow(Enterprise::Billing::CreateStripeCustomerService).to receive(:new).and_return(stripe_customer_service)
      allow(stripe_customer_service).to receive(:perform)
      stripe_event_service.new.perform(event: event)
      expect(Enterprise::Billing::CreateStripeCustomerService).to have_received(:new).with(account: account)
    end
  end
end
