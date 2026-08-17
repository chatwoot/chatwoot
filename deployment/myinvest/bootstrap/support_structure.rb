# frozen_string_literal: true

require 'json'

module Myinvest; end

class Myinvest::SupportStructure
  class ConfigurationError < StandardError; end

  PRODUCTION_CONFIRMATION = 'provision-support-structure:production'
  LABELS = [
    { title: 'support', color: '#1f93ff', description: 'General support request' },
    { title: 'billing', color: '#f59e0b', description: 'Billing or payment request' },
    { title: 'technical', color: '#8b5cf6', description: 'Technical support request' },
    { title: 'urgent', color: '#ef4444', description: 'Urgent human review required' }
  ].freeze
  TENANTS = {
    'saas' => { account_name: 'MyInvest Pro', teams: [{ name: 'Customer Support', description: 'MyInvest Pro first-line support' },
                                                      { name: 'Technical Escalations', description: 'MyInvest Pro technical escalation' }],
                response_targets_minutes: { urgent: 30, normal: 240 } },
    'new_academy' => { account_name: 'Academy Neu', teams: [{ name: 'Academy Support', description: 'Current Academy first-line support' },
                                                            { name: 'Course Operations', description: 'Current Academy course escalation' }],
                       response_targets_minutes: { urgent: 60, normal: 480 } },
    'legacy_academy' => { account_name: 'Academy Alt', teams: [{ name: 'Legacy Support', description: 'Legacy Academy first-line support' },
                                                               { name: 'Archive Review', description: 'Legacy support-history review' }],
                          response_targets_minutes: { urgent: 120, normal: 960 } }
  }.freeze

  def self.managed_rule_names
    ['MyInvest managed: route new conversations', 'MyInvest managed: prioritize urgent conversations']
  end

  def initialize(dry_run: true, confirmation: nil)
    @dry_run = dry_run
    @confirmation = confirmation
  end

  def call
    accounts = load_accounts!
    validate_history_inboxes!(accounts)
    validate_existing_rosters!(accounts)
    return result('dry-run', 'planned', build_plan(accounts)) if dry_run

    raise ConfigurationError, 'Exact production confirmation is required' unless confirmation == PRODUCTION_CONFIRMATION

    ActiveRecord::Base.transaction { accounts.each { |tenant_key, account| provision_account!(tenant_key, account) } }
    result('apply', 'applied', build_plan(accounts))
  end

  private

  attr_reader :dry_run, :confirmation

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def load_accounts!
    indexed = Hash.new { |hash, key| hash[key] = [] }
    canonical_names = TENANTS.values.map { |configuration| configuration.fetch(:account_name) }
    Account.find_each do |account|
      tenant_key = account.custom_attributes['myinvest_tenant_key']
      if tenant_key.present? && !TENANTS.key?(tenant_key)
        raise ConfigurationError, 'Unknown MyInvest tenant key; expected exactly the three canonical keys'
      end

      indexed[tenant_key] << account if TENANTS.key?(tenant_key)
      next unless canonical_names.include?(account.name) && !TENANTS.key?(tenant_key)

      raise ConfigurationError, 'Canonical account display name cannot be adopted without its tenant key'
    end
    accounts = TENANTS.to_h do |tenant_key, configuration|
      matches = indexed.fetch(tenant_key, [])
      raise ConfigurationError, "Tenant #{tenant_key} must resolve to exactly one account" unless matches.one?
      unless matches.first.name == configuration.fetch(:account_name)
        raise ConfigurationError, "Tenant #{tenant_key} account name does not match the canonical account"
      end

      [tenant_key, matches.first]
    end
    raise ConfigurationError, 'Canonical tenant accounts must have distinct IDs' unless accounts.values.map(&:id).uniq.length == TENANTS.length

    accounts
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def validate_history_inboxes!(accounts)
    accounts.each_value do |account|
      history_inboxes(account).each do |inbox|
        raise ConfigurationError, 'A history inbox has an attached AI bot' if inbox.agent_bot_inbox.present?
        raise ConfigurationError, 'A history inbox has a webhook' if inbox.webhooks.exists?
        raise ConfigurationError, 'A history inbox has an enabled integration hook' if inbox.hooks.enabled.exists?
        raise ConfigurationError, 'A history inbox has auto-assignment enabled' if inbox.enable_auto_assignment?
      end
    end
  end

  def history_inboxes(account)
    account.inboxes.select { |inbox| inbox.name.match?(/history|historie|archive/i) }
  end

  def build_plan(accounts)
    accounts.map do |tenant_key, account|
      { tenant_key: tenant_key, teams: TENANTS.fetch(tenant_key).fetch(:teams).length, labels: LABELS.length,
        inboxes: account.inboxes.length, history_inboxes: history_inboxes(account).length,
        automations: self.class.managed_rule_names.length }
    end
  end

  def provision_account!(tenant_key, account)
    configuration = TENANTS.fetch(tenant_key)
    members = account.account_users.includes(:user).map(&:user)
    teams = configuration.fetch(:teams).map { |attributes| upsert_team!(account, attributes, members) }
    LABELS.each { |attributes| upsert_label!(account, attributes) }
    live_inboxes(account).each { |inbox| members.each { |user| InboxMember.find_or_create_by!(inbox: inbox, user: user) } }
    update_response_targets!(account, configuration.fetch(:response_targets_minutes))
    upsert_automations!(account, teams.first)
    verify_rosters!(account, teams, members)
  end

  def validate_existing_rosters!(accounts)
    accounts.each do |tenant_key, account|
      roster_ids = account.account_users.pluck(:user_id)
      raise ConfigurationError, "Tenant #{tenant_key} has no human account roster" if roster_ids.empty?

      names = TENANTS.fetch(tenant_key).fetch(:teams).map { |team| team.fetch(:name).downcase }
      managed_team_ids = account.teams.where(name: names).pluck(:id)
      unexpected_team_members = TeamMember.where(team_id: managed_team_ids).where.not(user_id: roster_ids)
      unexpected_inbox_members = InboxMember.where(inbox: live_inboxes(account)).where.not(user_id: roster_ids)
      next unless unexpected_team_members.exists? || unexpected_inbox_members.exists?

      raise ConfigurationError, 'Managed routing roster contains a user outside the canonical account membership'
    end
  end

  def upsert_team!(account, attributes, members)
    team = unique_record!(account.teams, :name, attributes.fetch(:name).downcase, 'team')
    team ||= account.teams.new(name: attributes.fetch(:name))
    team.update!(description: attributes.fetch(:description), allow_auto_assign: true)
    members.each { |user| TeamMember.find_or_create_by!(team: team, user: user) }
    team
  end

  def upsert_label!(account, attributes)
    scope = Label.unscoped.where(account: account)
    label = unique_record!(scope, :title, attributes.fetch(:title), 'label') || account.labels.new(title: attributes.fetch(:title))
    label.update!(attributes)
  end

  def update_response_targets!(account, targets)
    operations = account.custom_attributes.fetch('support_operations', {}).merge(
      'managed_by' => 'myinvest-support-structure', 'response_targets_minutes' => targets.stringify_keys
    )
    account.update!(custom_attributes: account.custom_attributes.merge('support_operations' => operations))
  end

  def verify_rosters!(account, teams, members)
    expected_ids = members.map(&:id).sort
    teams.each do |team|
      raise ConfigurationError, 'Managed team roster verification failed' unless team.team_members.pluck(:user_id).sort == expected_ids
    end
    live_inboxes(account).each do |inbox|
      actual_ids = inbox.inbox_members.pluck(:user_id).sort
      raise ConfigurationError, 'Human inbox roster verification failed' unless actual_ids == expected_ids
    end
  end

  def live_inboxes(account)
    account.inboxes.to_a - history_inboxes(account)
  end

  def upsert_automations!(account, primary_team)
    inbox_ids = live_inboxes(account).map { |inbox| inbox.id.to_s }
    upsert_automation!(account, self.class.managed_rule_names.first, event_name: 'conversation_created',
                                                                     conditions: [condition('inbox_id', 'equal_to', inbox_ids)],
                                                                     actions: [
                                                                       action('assign_team', [primary_team.id]),
                                                                       action('add_label', ['support'])
                                                                     ])
    upsert_automation!(account, self.class.managed_rule_names.last, event_name: 'conversation_updated',
                                                                    conditions: [condition('labels', 'equal_to', ['urgent'])],
                                                                    actions: [action('change_priority', ['urgent'])])
  end

  def condition(attribute, operator, values)
    { 'attribute_key' => attribute, 'filter_operator' => operator, 'values' => values, 'query_operator' => nil }
  end

  def action(name, params)
    { 'action_name' => name, 'action_params' => params }
  end

  def upsert_automation!(account, name, attributes)
    rule = unique_record!(account.automation_rules, :name, name, 'automation') || account.automation_rules.new(name: name)
    rule.update!(attributes.merge(active: true, description: 'MyInvest managed: safe tenant-scoped routing'))
  end

  def unique_record!(scope, attribute, value, kind)
    records = scope.where(attribute => value).to_a
    raise ConfigurationError, "Managed #{kind} is not unique within its tenant" if records.length > 1

    records.first
  end

  def result(mode, status, tenants)
    { command: 'support-structure', mode: mode, status: status, tenants: tenants }
  end
end

if ENV['SUPPORT_STRUCTURE_RUN'] == 'true'
  dry_run = ENV.fetch('SUPPORT_STRUCTURE_MODE', 'dry-run') != 'apply'
  output = Myinvest::SupportStructure.new(dry_run: dry_run, confirmation: ENV.fetch('SUPPORT_STRUCTURE_CONFIRMATION', nil)).call
  # rubocop:disable Rails/Output -- machine-readable command output is the interface.
  $stdout.write("#{JSON.generate(output)}\n")
  # rubocop:enable Rails/Output
end
