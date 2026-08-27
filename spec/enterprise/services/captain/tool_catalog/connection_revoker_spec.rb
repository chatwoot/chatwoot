require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ConnectionRevoker do
  subject(:revoker) { described_class.new(account: account, registry: registry) }

  let(:account) { create(:account) }
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry) }

  before { allow(registry).to receive(:find).with('linear') }

  it 'revokes the provider token before deleting the local connection' do
    hook = create(
      :integrations_hook,
      :linear,
      account: account,
      access_token: 'linear-access-token',
      refresh_token: 'linear-refresh-token'
    )
    client = instance_double(Linear, revoke_token: true)
    allow(Linear).to receive(:new).with('linear-access-token', refresh_token: 'linear-refresh-token').and_return(client)
    installation = create(
      :captain_tool_catalog_installation,
      account: account,
      initiated_by: create(:user, account: account, role: :administrator),
      provider_key: 'linear',
      status: 'awaiting_connection',
      oauth_nonce_digest: Digest::SHA256.hexdigest('catalog-nonce')
    )

    revoker.perform(provider_key: 'linear')

    expect(client).to have_received(:revoke_token)
    expect { hook.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(installation.reload).to be_expired
    expect(installation.oauth_nonce_digest).to be_nil
  end

  it 'still deletes the local connection when provider revocation fails' do
    hook = create(:integrations_hook, :linear, account: account, access_token: 'linear-access-token')
    allow(Linear).to receive(:new).and_raise(StandardError, 'provider unavailable')

    revoker.perform(provider_key: 'linear')

    expect { hook.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
