require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ConnectionRequirement do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }

  it 'reports all scopes missing without an account connection' do
    result = service.check(provider_key: 'example', required_scopes: %w[customers:read customers:write])

    expect(result).not_to be_satisfied
    expect(result.hook).to be_nil
    expect(result.missing_scopes).to eq(%w[customers:read customers:write])
  end

  it 'normalizes comma and space separated scopes from an enabled connection' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:write, customers:read' })

    result = service.check(provider_key: 'example', required_scopes: %w[customers:read customers:write])

    expect(result).to be_satisfied
    expect(result.hook).to eq(hook)
    expect(result.missing_scopes).to eq([])
  end

  it 'does not treat a disabled hook as a usable connection' do
    create(:integrations_hook, account: account, app_id: 'example', status: 'disabled', settings: { scope: 'customers:read' })

    expect(service.check(provider_key: 'example', required_scopes: ['customers:read'])).not_to be_satisfied
  end

  it 'never considers a hook from another account' do
    create(:integrations_hook, account: create(:account), app_id: 'example', settings: { scope: 'customers:read' })

    result = service.check(provider_key: 'example', required_scopes: ['customers:read'])

    expect(result.hook).to be_nil
  end
end
