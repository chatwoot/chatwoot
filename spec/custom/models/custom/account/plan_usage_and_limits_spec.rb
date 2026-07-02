require 'rails_helper'

RSpec.describe Custom::Account::PlanUsageAndLimits do
  let(:account) { create(:account) }

  describe '#usage_limits' do
    it 'exposes the fork quota keys with unlimited defaults' do
      Custom::Account::PlanUsageAndLimits::QUOTA_RESOURCES.each do |resource|
        expect(account.usage_limits[resource.to_sym]).to eq ChatwootApp.max_limit.to_i
      end
    end

    it 'keeps the upstream keys intact' do
      expect(account.usage_limits).to include(:agents, :inboxes, :captain)
    end

    it 'resolves per-account overrides from the limits column' do
      account.update!(limits: { teams: 5, integrations: 2 })

      expect(account.usage_limits[:teams]).to eq 5
      expect(account.usage_limits[:integrations]).to eq 2
    end
  end

  describe 'limits validation' do
    it 'accepts the fork quota keys' do
      account.assign_attributes(limits: { teams: 3, webhooks: 1, agent_bots: 1, labels: 10,
                                          custom_attribute_definitions: 5, automation_rules: 5, integrations: 2 })

      expect(account).to be_valid
    end

    it 'still accepts the upstream keys' do
      account.assign_attributes(limits: { agents: 3, inboxes: 2, captain_responses: 100 })

      expect(account).to be_valid
    end

    it 'rejects unknown keys' do
      account.assign_attributes(limits: { bogus: 1 })

      expect(account).not_to be_valid
      expect(account.errors[:limits]).to be_present
    end
  end
end
