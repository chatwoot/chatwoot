require 'rails_helper'

RSpec.describe Custom::EntitlementService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account) }

  describe '#check' do
    it 'allows creation when no limit is configured' do
      result = service.check(:teams)

      expect(result.allowed?).to be true
      expect(result.current).to eq 0
      expect(result.limit).to eq ChatwootApp.max_limit.to_i
    end

    it 'denies creation at the cap and reports usage' do
      account.update!(limits: { teams: 1 })
      create(:team, account: account)

      result = service.check(:teams)

      expect(result.allowed?).to be false
      expect(result.resource).to eq :teams
      expect(result.current).to eq 1
      expect(result.limit).to eq 1
    end

    it 'allows creation below the cap' do
      account.update!(limits: { teams: 2 })
      create(:team, account: account)

      expect(service.check(:teams).allowed?).to be true
    end

    it 'counts only rows of the requested account' do
      account.update!(limits: { labels: 1 })
      create(:label, account: create(:account))

      expect(service.check(:labels).allowed?).to be true
    end

    it 'logs denials for observability' do
      account.update!(limits: { webhooks: 0 })
      allow(Rails.logger).to receive(:warn)

      service.check(:webhooks)

      expect(Rails.logger).to have_received(:warn)
        .with("[QUOTA] denied account_id=#{account.id} resource=webhooks current=0 limit=0")
    end

    it 'raises for unknown resources' do
      expect { service.check(:bogus) }.to raise_error(KeyError)
    end
  end

  describe 'platform-managed resources (ADR-0005)' do
    it 'excludes platform-managed agent bots from the count' do
      create(:agent_bot, account: account)
      create(:agent_bot, account: account, platform_managed: true)

      expect(service.usage(:agent_bots).current).to eq 1
    end

    it 'excludes platform-managed webhooks from the count' do
      create(:webhook, account: account, url: 'https://example.com/tenant')
      create(:webhook, account: account, url: 'https://example.com/platform', platform_managed: true)

      expect(service.usage(:webhooks).current).to eq 1
    end

    it 'excludes platform-managed account users from the agents count' do
      create(:account_user, account: account, user: create(:user))
      create(:account_user, account: account, user: create(:user), platform_managed: true)

      expect(service.usage(:agents).current).to eq 1
    end

    it 'still allows the tenant to fill their cap alongside platform infrastructure' do
      account.update!(limits: { agent_bots: 1 })
      create(:agent_bot, account: account, platform_managed: true)

      expect(service.check(:agent_bots).allowed?).to be true
      expect(service.usage(:agent_bots).current).to eq 0
    end
  end
end
