require 'rails_helper'

RSpec.describe Captain::ToolCatalog::BindingResolver do
  it 'quotes and escapes the trusted contact identity for Shopify search syntax' do
    resolver = described_class.new(
      provider_key: 'shopify',
      model_input: {},
      configuration: {},
      state: { contact: { email: 'customer"vip\\test@example.com', phone_number: '+15555550100' } },
      step_results: []
    )

    expect(resolver.resolve(query: { 'source' => 'shopify_contact_query' })).to eq(
      query: 'email:"customer\\"vip\\\\test@example.com" OR phone:"+15555550100"'
    )
  end

  it 'turns only the bounded model order number into an exact Shopify name filter' do
    resolver = described_class.new(
      provider_key: 'shopify',
      model_input: { order_number: '#1001' },
      configuration: {},
      state: {},
      step_results: []
    )

    expect(resolver.resolve(query: { 'source' => 'shopify_order_query', 'path' => 'order_number' })).to eq(
      query: 'name:"1001"'
    )
  end
end
