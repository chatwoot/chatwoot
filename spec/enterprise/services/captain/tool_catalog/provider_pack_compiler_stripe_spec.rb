require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackCompiler do
  subject(:pack) do
    described_class.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/stripe')
    ).compile
  end

  it 'compiles the reviewed read tools and keeps write tools approval-gated' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }

    expect(templates.keys).to contain_exactly(
      'cancel_subscription',
      'change_subscription_plan',
      'get_current_customer',
      'get_last_five_invoices',
      'get_last_five_payments',
      'get_subscription_status',
      'refund_payment'
    )
    expect(templates.values.select { |template| template.fetch('model_visible') }.pluck('key')).to contain_exactly(
      'get_current_customer',
      'get_last_five_invoices',
      'get_last_five_payments',
      'get_subscription_status'
    )
    expect(templates.values.reject { |template| template.fetch('model_visible') }.pluck('availability').uniq)
      .to eq(['approval_required'])
  end

  it 'binds runtime customer identity to the current contact and pins every endpoint to Stripe' do
    available_templates = pack.fetch('templates').select { |template| template.fetch('model_visible') }
    find_customer_steps = available_templates.map do |template|
      template.fetch('recipe').find { |step| step.fetch('operation_key') == 'find_customer' }
    end

    expect(find_customer_steps).to all(
      include('bindings' => include('email' => { 'source' => 'contact', 'path' => 'email' }))
    )
    expect(pack.fetch('operations').pluck('request').pluck('url')).to all(start_with('https://api.stripe.com/'))
    expect(pack.to_json).not_to include('client_secret', 'sk_live_', 'sk_test_', 'rk_live_', 'rk_test_')
  end
end
