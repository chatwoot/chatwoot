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

    it 'accepts the externally-enforced agentic_ai key' do
      # The control plane writes this cap via the Platform API; the schema must
      # allow it even though Chatwoot never enforces it (display-only).
      account.assign_attributes(limits: { agentic_ai: 500 })

      expect(account).to be_valid
    end

    it 'rejects unknown keys' do
      account.assign_attributes(limits: { bogus: 1 })

      expect(account).not_to be_valid
      expect(account.errors[:limits]).to be_present
    end

    it 'accepts every key the enterprise schema accepts (upstream-sync tripwire)' do
      # The fork REPLACES Enterprise#validate_limit_keys (its schema is
      # additionalProperties: false, so it cannot be extended). If upstream adds
      # a new limit key, the fork must mirror it in base_keys or writes of that
      # key start failing silently after a sync. Capture both schemas at the
      # JSONSchemer boundary and assert the fork's property set is a superset.
      account # materialize the lazy let (creation runs validations) before stubbing JSONSchemer

      captured_schemas = []
      allow(JSONSchemer).to receive(:schema).and_wrap_original do |original, schema|
        captured_schemas << schema
        original.call(schema)
      end

      Enterprise::Account::PlanUsageAndLimits.instance_method(:validate_limit_keys).bind_call(account)
      account.send(:validate_limit_keys)

      enterprise_keys, fork_keys = captured_schemas.map { |schema| schema['properties'].keys.map(&:to_s) }
      expect(fork_keys).to include(*enterprise_keys)
    end
  end
end
