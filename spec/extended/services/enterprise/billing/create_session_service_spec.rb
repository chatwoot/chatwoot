require 'rails_helper'

describe Enterprise::Billing::CreateSessionService do
  subject(:create_session_service) { described_class }

  describe '#perform' do
    it 'calls stripe billing portal session' do
      customer_id = 'cus_random_number'
      return_url = 'https://www.chatwoot.com'
      allow(Stripe::BillingPortal::Session).to receive(:create).with({ customer: customer_id, return_url: return_url })

      create_session_service.new.create_session(customer_id, return_url)

      expect(Stripe::BillingPortal::Session).to have_received(:create).with(
        {
          customer: customer_id,
          return_url: return_url
        }
      )
    end
  end
end
