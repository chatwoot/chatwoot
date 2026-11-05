# frozen_string_literal: true

require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  let!(:account) { create(:account, custom_attributes: { stripe_customer_id: 'cus_123' }) }
  let(:event) do
    Stripe::Event.construct_from(
      type: 'invoice.paid',
      created: Time.current.to_i,
      data: { object: { object: 'invoice', id: 'in_first', customer: 'cus_123', status: 'paid', amount_paid: 1900,
                        currency: 'usd', status_transitions: { paid_at: Time.current.to_i } } }
    )
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
  end

  it 'records the first payment for the Stripe-billed account' do
    described_class.new.perform(event: event)

    expect(account.reload.internal_attributes.dig('first_payment', 'invoice_id')).to eq('in_first')
  end

  it 'ignores invoices for customers without a Cloud account' do
    other_event = Stripe::Event.construct_from(event.to_hash.deep_merge(data: { object: { customer: 'cus_self_hosted' } }))

    expect { described_class.new.perform(event: other_event) }.not_to raise_error
    expect(account.reload.internal_attributes).not_to include('first_payment')
  end
end
