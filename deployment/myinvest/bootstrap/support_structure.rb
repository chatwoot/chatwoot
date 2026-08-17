# frozen_string_literal: true

require 'json'

module Myinvest; end

# rubocop:disable Metrics/ClassLength
class Myinvest::SupportStructure
  class ConfigurationError < StandardError; end

  PRODUCTION_CONFIRMATION = 'provision-support-structure:production'
  HISTORY_DELIVERY_SUBSCRIPTIONS = Webhook::ALLOWED_WEBHOOK_EVENTS.grep(/\A(?:conversation|message)_/).freeze
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

  def initialize(dry_run: true, confirmation: nil, rosters_json: ENV.fetch('SUPPORT_ROSTERS_JSON', nil))
    @dry_run = dry_run
    @confirmation = confirmation
    @rosters_json = rosters_json
  end

  def call
    accounts = load_accounts!
    validate_history_inboxes!(accounts)
    rosters = resolve_rosters!(accounts)
    validate_existing_rosters!(accounts, rosters)
    validate_automation_boundaries!(accounts, rosters)
    return result('dry-run', 'planned', build_plan(accounts)) if dry_run

    raise ConfigurationError, 'Exact production confirmation is required' unless confirmation == PRODUCTION_CONFIRMATION

    ActiveRecord::Base.transaction do
      accounts.each { |tenant_key, account| provision_account!(tenant_key, account, rosters.fetch(tenant_key)) }
    end
    result('apply', 'applied', build_plan(accounts))
  end

  private

  attr_reader :dry_run, :confirmation, :rosters_json

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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def validate_history_inboxes!(accounts)
    accounts.each_value do |account|
      histories = history_inboxes(account)
      raise ConfigurationError, 'A history inbox account has a relevant account-level webhook' if histories.any? && relevant_account_webhook?(account)
      if histories.any? && account.hooks.account_hooks.enabled.exists?
        raise ConfigurationError, 'A history inbox account has an enabled account-level integration hook'
      end

      histories.each do |inbox|
        raise ConfigurationError, 'A history inbox has an attached AI bot' if inbox.agent_bot_inbox.present?
        if inbox.channel.is_a?(Channel::Api) && inbox.channel.webhook_url.present?
          raise ConfigurationError, 'A history inbox API channel has channel webhook_url configured'
        end
        raise ConfigurationError, 'A history inbox has a webhook' if inbox.webhooks.exists?
        raise ConfigurationError, 'A history inbox has an enabled integration hook' if inbox.hooks.enabled.exists?
        raise ConfigurationError, 'A history inbox has auto-assignment enabled' if inbox.enable_auto_assignment?
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def relevant_account_webhook?(account)
    account.webhooks.account_type.where(inbox_id: nil).any? do |webhook|
      webhook.subscriptions.intersect?(HISTORY_DELIVERY_SUBSCRIPTIONS)
    end
  end

  def history_inboxes(account)
    account.inboxes.select do |inbox|
      durable_history = inbox.channel.is_a?(Channel::Api) && inbox.channel.additional_attributes['myinvest_history_import'] == true
      durable_history || inbox.name.match?(/history|historie|archive/i)
    end
  end

  def build_plan(accounts)
    accounts.map do |tenant_key, account|
      { tenant_key: tenant_key, teams: TENANTS.fetch(tenant_key).fetch(:teams).length, labels: LABELS.length,
        inboxes: account.inboxes.length, history_inboxes: history_inboxes(account).length,
        automations: self.class.managed_rule_names.length }
    end
  end

  def provision_account!(tenant_key, account, roster)
    configuration = TENANTS.fetch(tenant_key)
    teams = configuration.fetch(:teams).map do |attributes|
      upsert_team!(account, attributes, roster.fetch(:teams).fetch(attributes.fetch(:name)))
    end
    LABELS.each { |attributes| upsert_label!(account, attributes) }
    live_inboxes(account).each do |inbox|
      inbox.update!(enable_auto_assignment: false)
      roster.fetch(:inboxes).fetch(inbox.name).each { |user| InboxMember.find_or_create_by!(inbox: inbox, user: user) }
    end
    update_response_targets!(account, configuration.fetch(:response_targets_minutes))
    upsert_automations!(account, teams.first)
    verify_rosters!(account, teams, roster)
  end

  def resolve_rosters!(accounts)
    raise ConfigurationError, 'SUPPORT_ROSTERS_JSON is required' if rosters_json.blank?

    parsed = JSON.parse(rosters_json)
    unless parsed.is_a?(Hash) && parsed.keys.sort == TENANTS.keys.sort
      raise ConfigurationError, 'SUPPORT_ROSTERS_JSON must contain exactly the canonical tenant keys'
    end

    accounts.to_h { |tenant_key, account| [tenant_key, resolve_tenant_roster!(tenant_key, account, parsed.fetch(tenant_key))] }
  rescue JSON::ParserError, TypeError
    raise ConfigurationError, 'SUPPORT_ROSTERS_JSON is invalid'
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def resolve_tenant_roster!(tenant_key, account, roster)
    unless roster.is_a?(Hash) && roster.keys.sort == %w[inboxes teams] && roster.values.all?(Hash)
      raise ConfigurationError, "Tenant #{tenant_key} roster must contain only inboxes and teams"
    end

    inbox_names = live_inboxes(account).map(&:name)
    team_names = TENANTS.fetch(tenant_key).fetch(:teams).map { |team| team.fetch(:name) }
    unless roster.fetch('inboxes').keys.sort == inbox_names.sort && roster.fetch('teams').keys.sort == team_names.sort
      raise ConfigurationError, "Tenant #{tenant_key} roster keys do not match managed inboxes and teams"
    end

    users_by_email = account.account_users.includes(:user).to_h { |membership| [membership.user.email.downcase, membership.user] }
    resolved = { inboxes: resolve_roster_group!(roster.fetch('inboxes'), users_by_email),
                 teams: resolve_roster_group!(roster.fetch('teams'), users_by_email) }
    team_rosters = resolved.fetch(:teams).values.map { |users| users.map(&:id).sort }
    raise ConfigurationError, "Tenant #{tenant_key} managed team rosters must be distinct" unless team_rosters.uniq.length == team_rosters.length

    resolved
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def resolve_roster_group!(group, users_by_email)
    group.to_h do |name, identities|
      unless identities.is_a?(Array) && identities.any? && identities.all? { |identity| identity.is_a?(String) && identity.present? }
        raise ConfigurationError, 'Roster identities must be non-empty email arrays'
      end

      normalized = identities.map(&:downcase)
      raise ConfigurationError, 'Roster contains duplicate identities' unless normalized.uniq.length == normalized.length
      raise ConfigurationError, 'Roster contains an unknown account identity' unless normalized.all? { |email| users_by_email.key?(email) }

      [name, normalized.map { |email| users_by_email.fetch(email) }]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def validate_existing_rosters!(accounts, rosters)
    accounts.each do |tenant_key, account|
      roster = rosters.fetch(tenant_key)
      TENANTS.fetch(tenant_key).fetch(:teams).each do |attributes|
        team = account.teams.find_by(name: attributes.fetch(:name).downcase)
        validate_existing_ids!(team&.member_ids || [], roster.fetch(:teams).fetch(attributes.fetch(:name)).map(&:id))
      end
    end
  end

  def validate_existing_ids!(existing_ids, roster_ids)
    return if (existing_ids - roster_ids).empty?

    raise ConfigurationError, 'Managed roster contains an identity not explicitly designated'
  end

  def validate_automation_boundaries!(accounts, rosters)
    accounts.each do |tenant_key, account|
      roster = rosters.fetch(tenant_key)
      managed_teams = existing_managed_teams(account, tenant_key)
      validate_auto_assignment_teams!(account, managed_teams, roster)
      validate_active_automations!(account, managed_teams, roster, history_inboxes(account).any?)
    end
  end

  def existing_managed_teams(account, tenant_key)
    TENANTS.fetch(tenant_key).fetch(:teams).to_h do |attributes|
      name = attributes.fetch(:name)
      [name, account.teams.find_by(name: name.downcase)]
    end
  end

  def validate_auto_assignment_teams!(account, managed_teams, roster)
    managed_names = managed_teams.keys.map(&:downcase)
    if account.teams.where(allow_auto_assign: true).where.not(name: managed_names).exists?
      raise ConfigurationError, 'Automatic assignment is enabled for an unmanaged team'
    end

    managed_teams.each do |name, team|
      next unless team&.allow_auto_assign?

      validate_exact_team_roster!(team, roster.fetch(:teams).fetch(name))
    end
  end

  def validate_active_automations!(account, managed_teams, roster, history_present)
    rules = account.automation_rules.active.where.not(name: self.class.managed_rule_names)
    rules.find_each do |rule|
      if history_present && !live_inbox_scoped?(rule, account)
        raise ConfigurationError, 'An active account automation does not have a fail-closed live inbox scope'
      end

      validate_automation_assignments!(rule, managed_teams, roster)
    end
  end

  def live_inbox_scoped?(rule, account)
    conditions = rule.conditions
    return false unless conditions.is_a?(Array) && conditions.any? && conjunctive_conditions?(conditions)

    inbox_conditions = conditions.select { |condition| condition['attribute_key'] == 'inbox_id' }
    return false unless inbox_conditions.one?

    live_ids = live_inboxes(account).map { |inbox| inbox.id.to_s }
    valid_live_inbox_condition?(inbox_conditions.first, live_ids)
  end

  def valid_live_inbox_condition?(condition, live_ids)
    values = condition['values']
    return false unless condition['filter_operator'] == 'equal_to'
    return false unless values.is_a?(Array) && values.any?

    normalized_values = values.map(&:to_s)
    normalized_values.uniq.length == normalized_values.length && (normalized_values - live_ids).empty?
  end

  def conjunctive_conditions?(conditions)
    conditions.each_with_index.all? do |condition, index|
      operator = condition['query_operator'].presence&.upcase
      index == conditions.length - 1 ? operator.nil? : operator == 'AND'
    end
  end

  def validate_automation_assignments!(rule, managed_teams, roster)
    rule.actions.each do |automation_action|
      action_name = automation_action['action_name']
      next unless %w[assign_agent assign_team].include?(action_name)

      raise ConfigurationError, 'Active automation assignments must use a verified managed team' if action_name == 'assign_agent'

      target_ids = Array(automation_action['action_params']).map(&:to_s)
      managed_team = managed_teams.compact.find { |_name, candidate| target_ids == [candidate.id.to_s] }
      raise ConfigurationError, 'Active automation assignments must use a verified managed team' unless managed_team

      name, team = managed_team
      validate_exact_team_roster!(team, roster.fetch(:teams).fetch(name))
    end
  end

  def validate_exact_team_roster!(team, expected_members)
    expected_ids = expected_members.map(&:id).sort
    return if expected_ids.any? && team.member_ids.sort == expected_ids

    raise ConfigurationError, 'Automatic assignment managed team roster is not exact and non-empty'
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

  def verify_rosters!(account, teams, roster)
    teams.each do |team|
      validate_exact_team_roster!(team, roster.fetch(:teams).fetch(team.name.titleize))
      raise ConfigurationError, 'Managed team roster verification failed' unless team.allow_auto_assign?
    end
    live_inboxes(account).each do |inbox|
      expected_ids = roster.fetch(:inboxes).fetch(inbox.name).map(&:id).sort
      raise ConfigurationError, 'Human inbox roster verification failed' unless (expected_ids - inbox.member_ids).empty?
      raise ConfigurationError, 'Live inbox auto-assignment was not disabled' if inbox.enable_auto_assignment?
    end
  end

  def live_inboxes(account)
    account.inboxes.to_a - history_inboxes(account)
  end

  def upsert_automations!(account, primary_team)
    inbox_ids = live_inboxes(account).map { |inbox| inbox.id.to_s }
    raise ConfigurationError, 'Managed automations require a non-empty live inbox scope' if inbox_ids.empty?

    upsert_automation!(account, self.class.managed_rule_names.first, event_name: 'conversation_created',
                                                                     conditions: [condition('inbox_id', 'equal_to', inbox_ids)],
                                                                     actions: [
                                                                       action('assign_team', [primary_team.id]),
                                                                       action('add_label', ['support'])
                                                                     ])
    upsert_automation!(account, self.class.managed_rule_names.last, event_name: 'conversation_updated',
                                                                    conditions: [condition('inbox_id', 'equal_to', inbox_ids, 'AND'),
                                                                                 condition('labels', 'equal_to', ['urgent'])],
                                                                    actions: [action('change_priority', ['urgent'])])
  end

  def condition(attribute, operator, values, query_operator = nil)
    { 'attribute_key' => attribute, 'filter_operator' => operator, 'values' => values, 'query_operator' => query_operator }
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
# rubocop:enable Metrics/ClassLength

if ENV['SUPPORT_STRUCTURE_RUN'] == 'true'
  dry_run = ENV.fetch('SUPPORT_STRUCTURE_MODE', 'dry-run') != 'apply'
  output = Myinvest::SupportStructure.new(dry_run: dry_run, confirmation: ENV.fetch('SUPPORT_STRUCTURE_CONFIRMATION', nil)).call
  # rubocop:disable Rails/Output -- machine-readable command output is the interface.
  $stdout.write("#{JSON.generate(output)}\n")
  # rubocop:enable Rails/Output
end
