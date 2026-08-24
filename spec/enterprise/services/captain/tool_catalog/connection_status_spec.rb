require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ConnectionStatus do
  it 'treats a validated catalog-only Slack hook as connected without enabling legacy Slack mirroring' do
    slack_hook = build(
      :integrations_hook,
      app_id: 'slack',
      status: 'disabled',
      settings: { catalog_connected: true }
    )
    other_hook = build(
      :integrations_hook,
      app_id: 'linear',
      status: 'disabled',
      settings: { catalog_connected: true }
    )

    expect(described_class.connected?(slack_hook)).to be(true)
    expect(described_class.connected?(other_hook)).to be(false)
  end
end
