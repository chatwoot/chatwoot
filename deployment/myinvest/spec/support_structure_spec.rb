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
        expect(first_line_team.members).not_to include(admin)
        expect(escalation_team.members).not_to include(admin)
        expect(account.automation_rules.where(name: described_class.managed_rule_names)).to have_attributes(count: 2)
        action_names = account.automation_rules.flat_map(&:actions).pluck('action_name')
        expect(action_names).not_to include('send_message', 'send_email_to_team', 'send_webhook_event')

        routing_rule = account.automation_rules.find_by!(name: described_class.managed_rule_names.first)
        routed_team_id = routing_rule.actions.find { |action| action.fetch('action_name') == 'assign_team' }.fetch('action_params').first
        expect(account.teams.find(routed_team_id).members).to contain_exactly(first_line)
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

    it 'preserves unrelated records and user memberships' do
      account = accounts.fetch('saas')
      unrelated_team = create(:team, account: account, name: 'bespoke team', description: 'keep me')
      unrelated_rule = create(:automation_rule, account: account, name: 'Customer rule')

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
