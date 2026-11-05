# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::FirstPaymentService do
  let(:account) { create(:account) }
  let(:paid_at) { Time.zone.parse('2026-11-12T08:30:00Z') }
  let(:invoice_attributes) do
    { id: 'in_first', customer: 'cus_123', status: 'paid', amount_paid: 1900, currency: 'usd',
      status_transitions: { paid_at: paid_at.to_i } }
  end
  let(:invoice) { Stripe::Invoice.construct_from(invoice_attributes) }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
  end

  it 'records the first successful non-zero payment with a stable event id' do
    expect do
      described_class.new(account: account, invoice: invoice).perform
    end.to have_enqueued_job(Internal::Accounts::XConversionTrackingJob).with(account.id, 'cloud_first_payment')

    expect(account.reload.internal_attributes['first_payment']).to eq(
      'event_id' => "cloud_first_payment-account-#{account.id}",
      'invoice_id' => 'in_first',
      'paid_at' => paid_at.iso8601,
      'amount_paid' => 1900,
      'currency' => 'usd'
    )
  end

  it 'ignores $0 invoices such as trials' do
    invoice_attributes[:amount_paid] = 0

    described_class.new(account: account, invoice: invoice).perform

    expect(account.reload.internal_attributes).not_to include('first_payment')
    expect(Internal::Accounts::XConversionTrackingJob).not_to have_been_enqueued
  end

  it 'ignores invoices that are not paid' do
    invoice_attributes[:status] = 'open'

    described_class.new(account: account, invoice: invoice).perform

    expect(account.reload.internal_attributes).not_to include('first_payment')
  end

  it 'keeps the first payment when a later invoice or a webhook retry arrives' do
    described_class.new(account: account, invoice: invoice).perform
    later_invoice = Stripe::Invoice.construct_from(invoice_attributes.merge(id: 'in_second', amount_paid: 5700,
                                                                            status_transitions: { paid_at: (paid_at + 1.month).to_i }))

    expect do
      described_class.new(account: account, invoice: later_invoice).perform
      described_class.new(account: account, invoice: invoice).perform
    end.not_to have_enqueued_job(Internal::Accounts::XConversionTrackingJob)

    expect(account.reload.internal_attributes.dig('first_payment', 'invoice_id')).to eq('in_first')
  end

  it 'keeps other internal attributes' do
    account.update!(internal_attributes: { 'marketing_attribution' => { 'last_touch' => { 'twclid' => 'x-click-1' } } })

    described_class.new(account: account, invoice: invoice).perform

    expect(account.reload.internal_attributes.dig('marketing_attribution', 'last_touch', 'twclid')).to eq('x-click-1')
  end
end
