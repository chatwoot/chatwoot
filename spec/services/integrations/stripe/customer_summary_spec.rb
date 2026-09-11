require 'rails_helper'

RSpec.describe Integrations::Stripe::CustomerSummary do
  let(:connection) { instance_double(Integrations::Stripe::Connection, api_token: 'sandbox-token') }
  let(:contact) { build(:contact, email: 'alfred@example.com') }
  let(:service) { described_class.new(connection: connection, contact: contact) }
  let(:customer) { { id: 'cus_alfred', name: 'Alfred', email: contact.email, metadata: { private: 'hidden' } } }
  let(:customers) { [customer] }

  before do
    stub_request(:get, 'https://api.stripe.com/v1/customers/search')
      .with(query: { query: "email:#{contact.email.to_json}", limit: 100 }, headers: { 'Authorization' => 'Bearer sandbox-token' })
      .to_return(headers: { 'Content-Type' => 'application/json' }, body: { data: customers, has_more: false }.to_json)
    stub_request(:get, 'https://api.stripe.com/v1/subscriptions')
      .with(query: { customer: 'cus_alfred', status: 'all', limit: 5 })
      .to_return(headers: { 'Content-Type' => 'application/json' }, body: { data: [{ id: 'sub_test', status: 'active', metadata: {} }] }.to_json)
    stub_request(:get, 'https://api.stripe.com/v1/invoices')
      .with(query: { customer: 'cus_alfred', limit: 5 })
      .to_return(headers: { 'Content-Type' => 'application/json' },
                 body: { data: [{ id: 'in_test', total: 1000, currency: 'usd', status: 'paid', metadata: {} }] }.to_json)
  end

  it 'matches the contact email and returns only sidebar fields' do
    result = service.perform
    expect(result[:customer]).to eq(customer.except(:metadata))
    expect(result[:subscriptions]).to eq([{ id: 'sub_test', status: 'active' }])
    expect(result[:invoices]).to eq([{ id: 'in_test', total: 1000, currency: 'usd', status: 'paid' }])
  end

  it 'does not call Stripe when the contact has no email' do
    contact.email = nil
    expect(connection).not_to receive(:api_token)
    expect(service.perform).to eq(customers: [], missing_email: true)
  end

  context 'without a matching customer' do
    let(:customers) { [] }

    it 'returns an empty list without billing details' do
      expect(service.perform).to eq(customers: [], has_more_customers: false)
    end
  end

  context 'with duplicate email addresses' do
    let(:customers) { [customer, customer.merge(id: 'cus_second')] }

    it 'requires an explicit choice' do
      expect(service.perform).not_to have_key(:customer)
      expect(service.perform(customer_id: 'cus_alfred')[:customer][:id]).to eq('cus_alfred')
    end
  end

  context 'with mixed-case and partial search matches' do
    let(:customers) { [customer.merge(email: 'Alfred@Example.COM'), customer.merge(id: 'cus_other', email: 'alfred@example.com.au')] }

    it 'matches case-insensitively while rejecting partial email matches' do
      result = service.perform
      expect(result[:customers].pluck(:id)).to eq(['cus_alfred'])
      expect(result[:customer][:id]).to eq('cus_alfred')
      expect { service.perform(customer_id: 'cus_other') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with quotes in the email' do
    let(:contact) { build(:contact, email: '"alfred"@example.com') }

    it 'escapes the email in the search query' do
      expect(service.perform[:customer][:id]).to eq('cus_alfred')
    end
  end

  it 'rejects a customer ID that does not match the contact email' do
    expect { service.perform(customer_id: 'cus_unrelated') }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
