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
end
