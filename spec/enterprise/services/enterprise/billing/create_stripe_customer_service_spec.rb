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

        create_stripe_customer_service.new(account: account).perform

        expect(Stripe::Customer).not_to have_received(:create)
        expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_existing_customer')
      end
    end
  end
end
