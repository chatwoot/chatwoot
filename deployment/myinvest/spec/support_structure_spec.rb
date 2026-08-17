require 'rails_helper'
require Rails.root.join('deployment/myinvest/bootstrap/support_structure')

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Myinvest::SupportStructure do
  subject(:provisioner) { described_class.new(dry_run: dry_run, confirmation: confirmation, rosters_json: rosters_json) }

  let(:dry_run) { true }
  let(:confirmation) { nil }
  let(:admin) { create(:user) }
  let(:first_line) { create(:user) }
  let(:escalation) { create(:user) }
  let!(:accounts) do
    described_class::TENANTS.to_h do |tenant_key, configuration|
      account = create(:account, name: configuration.fetch(:account_name), custom_attributes: { 'myinvest_tenant_key' => tenant_key })
      create(:account_user, account: account, user: admin, role: :administrator)
      create(:account_user, account: account, user: first_line, role: :agent)
      create(:account_user, account: account, user: escalation, role: :agent)
      inbox = create(:inbox, account: account, name: "#{configuration.fetch(:account_name)} Website", enable_auto_assignment: true)
      create(:inbox_member, inbox: inbox, user: admin)
      [tenant_key, account]
    end
  end
  let(:rosters_json) do
    JSON.generate(accounts.to_h do |tenant_key, account|
      team_names = described_class::TENANTS.fetch(tenant_key).fetch(:teams).map { |team| team.fetch(:name) }
      [tenant_key, { inboxes: { account.inboxes.first.name => [first_line.email, escalation.email] },
                     teams: { team_names.first => [first_line.email], team_names.last => [escalation.email] } }]
    end)
  end

  it 'defaults to a non-mutating, structured dry run' do
    result = provisioner.call

    expect(result).to include(mode: 'dry-run', status: 'planned')
    expect(result.fetch(:tenants).map { |tenant| tenant.fetch(:tenant_key) }).to eq(described_class::TENANTS.keys)
    expect(Team.count).to eq(0)
    expect(Label.count).to eq(0)
    expect(AutomationRule.count).to eq(0)
  end

  context 'when applying the structure' do
    let(:dry_run) { false }
    let(:confirmation) { described_class::PRODUCTION_CONFIRMATION }

    # rubocop:disable RSpec/MultipleExpectations
    it 'idempotently provisions tenant-scoped teams, labels, memberships, routing, and priority rules' do
      2.times { provisioner.call }

      accounts.each do |tenant_key, account|
        configuration = described_class::TENANTS.fetch(tenant_key)
        expect(account.teams.pluck(:name)).to match_array(configuration.fetch(:teams).map { |team| team.fetch(:name).downcase })
        expect(account.labels.pluck(:title)).to match_array(described_class::LABELS.map { |label| label.fetch(:title) })
        expect(account.inboxes.first.members).to contain_exactly(admin, first_line, escalation)
        expect(account.account_users.find_by!(user: admin)).to be_administrator
        expect(account.inboxes.first.reload.enable_auto_assignment).to be(false)
        first_line_team, escalation_team = configuration.fetch(:teams).map do |team|
          account.teams.find_by!(name: team.fetch(:name).downcase)
        end
        expect(first_line_team.members).to contain_exactly(first_line)
        expect(escalation_team.members).to contain_exactly(escalation)
        expect(first_line_team).to be_allow_auto_assign
        expect(escalation_team).to be_allow_auto_assign
        expect(first_line_team.members).not_to include(admin)
        expect(escalation_team.members).not_to include(admin)
        expect(account.automation_rules.where(name: described_class.managed_rule_names)).to have_attributes(count: 2)
        action_names = account.automation_rules.flat_map(&:actions).pluck('action_name')
        expect(action_names).not_to include('send_message', 'send_email_to_team', 'send_webhook_event')

        routing_rule = account.automation_rules.find_by!(name: described_class.managed_rule_names.first)
        routed_team_id = routing_rule.actions.find { |action| action.fetch('action_name') == 'assign_team' }.fetch('action_params').first
        expect(account.teams.find(routed_team_id).members).to contain_exactly(first_line)

        live_inbox_ids = account.inboxes.ids.map(&:to_s)
        account.automation_rules.where(name: described_class.managed_rule_names).find_each do |rule|
          inbox_condition = rule.conditions.find { |condition| condition.fetch('attribute_key') == 'inbox_id' }
          expect(inbox_condition).to include('filter_operator' => 'equal_to', 'values' => match_array(live_inbox_ids))
          expect(rule.conditions.drop(1).pluck('query_operator')).to all(be_nil)
        end
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'requires explicit, tenant-scoped rosters before writing' do
      expect do
        described_class.new(dry_run: false, confirmation: confirmation, rosters_json: nil).call
      end.to raise_error(Myinvest::SupportStructure::ConfigurationError, /SUPPORT_ROSTERS_JSON/)
      expect(Team.count).to eq(0)
    end

    it 'rejects unknown and duplicate roster identities before writing' do
      parsed = JSON.parse(rosters_json)
      parsed.fetch('saas').fetch('teams').values.first.replace([first_line.email, first_line.email, 'missing@example.com'])

      expect do
        described_class.new(dry_run: false, confirmation: confirmation, rosters_json: JSON.generate(parsed)).call
      end.to raise_error(Myinvest::SupportStructure::ConfigurationError, /duplicate identities/)
      expect(Team.count).to eq(0)
    end

    it 'rejects an unknown roster identity before writing' do
      parsed = JSON.parse(rosters_json)
      parsed.fetch('saas').fetch('teams').values.first.replace(['missing@example.com'])

      expect do
        described_class.new(dry_run: false, confirmation: confirmation, rosters_json: JSON.generate(parsed)).call
      end.to raise_error(Myinvest::SupportStructure::ConfigurationError, /unknown account identity/)
      expect(Team.count).to eq(0)
    end

    it 'rejects missing identities and identical managed-team rosters before writing' do
      parsed = JSON.parse(rosters_json)
      parsed.fetch('saas').fetch('inboxes').values.first.replace([])
      expect do
        described_class.new(dry_run: false, confirmation: confirmation, rosters_json: JSON.generate(parsed)).call
      end.to raise_error(Myinvest::SupportStructure::ConfigurationError, /non-empty email arrays/)

      parsed = JSON.parse(rosters_json)
      parsed.fetch('saas').fetch('teams').values.last.replace([first_line.email])
      expect do
        described_class.new(dry_run: false, confirmation: confirmation, rosters_json: JSON.generate(parsed)).call
      end.to raise_error(Myinvest::SupportStructure::ConfigurationError, /team rosters must be distinct/)
      expect(Team.count).to eq(0)
    end

    it 'uses durable API metadata and rejects channel webhook_url without an Inbox Webhook row' do
      account = accounts.fetch('legacy_academy')
      channel = create(:channel_api, account: account, webhook_url: 'https://example.test/history',
                                     additional_attributes: { 'myinvest_history_import' => true })
      history = create(:inbox, account: account, channel: channel, name: 'Imported records', enable_auto_assignment: false)

      expect(history.webhooks).to be_empty
      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /channel webhook_url/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects a relevant account-level webhook for an otherwise inert durable history inbox' do
      account = accounts.fetch('legacy_academy')
      channel = create(:channel_api, account: account, webhook_url: nil,
                                     additional_attributes: { 'myinvest_history_import' => true })
      history = create(:inbox, account: account, channel: channel, name: 'Imported records', enable_auto_assignment: false)
      create(:webhook, account_id: account.id, inbox_id: nil, webhook_type: :account_type,
                       subscriptions: %w[conversation_created message_created])

      expect(history.webhooks).to be_empty
      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /account-level webhook/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects an enabled account-level integration hook when the account has history' do
      account = accounts.fetch('legacy_academy')
      create(:inbox, account: account, name: 'Imported History', enable_auto_assignment: false)
      create(:integrations_hook, account: account, status: :enabled)

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /account-level integration hook/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects active account automations that can reach history conversations' do
      account = accounts.fetch('legacy_academy')
      create(:inbox, account: account, name: 'Imported History', enable_auto_assignment: false)
      create(:automation_rule, account: account, name: 'Unsafe history automation',
                               conditions: [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
                                              'values' => ['open'], 'query_operator' => nil }],
                               actions: [{ 'action_name' => 'send_message', 'action_params' => ['unsafe'] },
                                         { 'action_name' => 'send_webhook_event',
                                           'action_params' => ['https://example.test/unsafe'] },
                                         { 'action_name' => 'change_priority', 'action_params' => ['urgent'] }])

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /live inbox scope/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects an OR condition that can bypass an active automation live inbox scope' do
      account = accounts.fetch('legacy_academy')
      live_inbox = account.inboxes.first
      create(:inbox, account: account, name: 'Imported History', enable_auto_assignment: false)
      create(:automation_rule, account: account, name: 'Bypassable history automation',
                               conditions: [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                              'values' => [live_inbox.id], 'query_operator' => 'OR' },
                                            { 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
                                              'values' => ['open'], 'query_operator' => nil }],
                               actions: [{ 'action_name' => 'add_label', 'action_params' => ['support'] }])

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /live inbox scope/i)
      expect(Team.count).to eq(0)
    end

    it 'allows a conjunctive active automation scoped to verified live inboxes' do
      account = accounts.fetch('legacy_academy')
      live_inbox = account.inboxes.first
      create(:inbox, account: account, name: 'Imported History', enable_auto_assignment: false)
      rule = create(:automation_rule, account: account, name: 'Safe live automation',
                                      conditions: [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                                     'values' => [live_inbox.id], 'query_operator' => 'AND' },
                                                   { 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
                                                     'values' => ['open'], 'query_operator' => nil }],
                                      actions: [{ 'action_name' => 'add_label', 'action_params' => ['support'] }])

      provisioner.call

      expect(rule.reload).to be_active
    end

    it 'rejects active automations that assign agents directly or route through unmanaged teams' do
      account = accounts.fetch('saas')
      live_inbox = account.inboxes.first
      unmanaged_team = create(:team, account: account, name: 'unmanaged', allow_auto_assign: false)
      conditions = [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                      'values' => [live_inbox.id], 'query_operator' => nil }]
      create(:automation_rule, account: account, name: 'Direct administrator assignment', conditions: conditions,
                               actions: [{ 'action_name' => 'assign_agent', 'action_params' => [admin.id] }])
      create(:automation_rule, account: account, name: 'Unmanaged team assignment', conditions: conditions,
                               actions: [{ 'action_name' => 'assign_team', 'action_params' => [unmanaged_team.id] }])

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /managed team/i)
      expect(Team.where.not(id: unmanaged_team.id)).to be_empty
    end

    it 'rejects automatic assignment through an unmanaged team without changing it' do
      account = accounts.fetch('saas')
      unmanaged_team = create(:team, account: account, name: 'stale routing team', allow_auto_assign: true)
      create(:team_member, team: unmanaged_team, user: admin)

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /unmanaged team/i)
      expect(unmanaged_team.reload).to be_allow_auto_assign
      expect(unmanaged_team.members).to contain_exactly(admin)
    end

    it 'preserves unrelated records and user memberships' do
      account = accounts.fetch('saas')
      unrelated_team = create(:team, account: account, name: 'bespoke team', description: 'keep me', allow_auto_assign: false)
      unrelated_rule = create(:automation_rule, account: account, name: 'Customer rule',
                                                actions: [{ 'action_name' => 'add_label', 'action_params' => ['customer'] }])

      provisioner.call

      expect(unrelated_team.reload.description).to eq('keep me')
      expect(unrelated_rule.reload).to be_present
    end

    it 'fails closed for duplicate tenant keys before writing' do
      create(:account, custom_attributes: { 'myinvest_tenant_key' => 'saas' })

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /exactly one account/)
      expect(Team.count).to eq(0)
    end

    it 'rejects display-name adoption without a canonical tenant key before writing' do
      create(:account, name: described_class::TENANTS.fetch('saas').fetch(:account_name))

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /display name/)
      expect(Team.count).to eq(0)
    end

    it 'rejects unknown tenant keys before writing' do
      create(:account, custom_attributes: { 'myinvest_tenant_key' => 'other' })

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /three canonical keys/)
      expect(Team.count).to eq(0)
    end

    it 'rejects an AI bot attached to a history inbox before writing' do
      account = accounts.fetch('legacy_academy')
      history = create(:inbox, account: account, name: 'MyInvest24 History')
      create(:agent_bot_inbox, inbox: history, agent_bot: create(:agent_bot, account: account))

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /history inbox.*bot/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects unsafe history inbox routing integrations before writing' do
      account = accounts.fetch('legacy_academy')
      history = create(:inbox, account: account, name: 'Support Archive', enable_auto_assignment: false)
      create(:webhook, account_id: account.id, inbox_id: history.id, webhook_type: :inbox_type)

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /history inbox has a webhook/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects an enabled history inbox integration hook before writing' do
      account = accounts.fetch('legacy_academy')
      history = create(:inbox, account: account, name: 'Legacy History', enable_auto_assignment: false)
      create(:integrations_hook, :dialogflow, account: account, inbox: history, status: :enabled)

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /enabled integration hook/i)
      expect(Team.count).to eq(0)
    end

    it 'rejects history inbox auto-assignment before writing' do
      account = accounts.fetch('legacy_academy')
      create(:inbox, account: account, name: 'Support History', enable_auto_assignment: true)

      expect { provisioner.call }.to raise_error(Myinvest::SupportStructure::ConfigurationError, /auto-assignment/)
      expect(Team.count).to eq(0)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
