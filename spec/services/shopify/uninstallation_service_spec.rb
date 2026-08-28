require 'rails_helper'

RSpec.describe Shopify::UninstallationService do
  let(:account) { create(:account) }
  let(:connected_at) { Time.iso8601('2026-07-29T10:01:00.000000Z') }
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      access_token: 'shopify-access-token',
      settings: {
        'scope' => 'read_customers,read_orders',
        'connected_at' => connected_at.iso8601(6),
        'installation_id' => SecureRandom.uuid
      }
    )
  end

  before do
    account.enable_features!('shopify_integration')
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
  end

  it 'removes the integration for the current installation' do
    hook

    expect do
      described_class.new(hook: hook, occurred_at: connected_at + 1.minute).perform
    end.to change(Integrations::Hook, :count).by(-1)

    expect(account.reload.internal_attributes[Shopify::InstallationGeneration::KEY]).to eq(1)
  end

  it 'ignores an uninstall event from before the current installation' do
    result = described_class.new(hook: hook, occurred_at: connected_at - 1.minute).perform

    expect(result).to eq(:stale)
    expect(hook.reload).to have_attributes(
      status: 'enabled',
      access_token: 'shopify-access-token'
    )
    expect(account.reload.internal_attributes[Shopify::InstallationGeneration::KEY]).to be_nil
  end

  it 'reloads the installation generation while holding the hook lock' do
    replacement_connected_at = connected_at + 2.minutes
    Integrations::Hook.find(hook.id).update!(
      settings: hook.settings.merge('connected_at' => replacement_connected_at.iso8601(6))
    )

    result = described_class.new(hook: hook, occurred_at: connected_at + 1.minute).perform

    expect(result).to eq(:stale)
    expect(hook.reload).to have_attributes(
      status: 'enabled',
      access_token: 'shopify-access-token'
    )
  end

  it 'supports lifecycle calls without an occurrence timestamp' do
    hook

    expect do
      described_class.new(hook: hook).perform
    end.to change(Integrations::Hook, :count).by(-1)
  end

  it 'still cleans up when the account feature is disabled' do
    hook
    account.disable_features!('shopify_integration')

    expect do
      described_class.new(hook: hook, occurred_at: connected_at + 1.minute).perform
    end.to change(Integrations::Hook, :count).by(-1)
  end
end
