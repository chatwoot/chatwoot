# frozen_string_literal: true

# CUSTOMIZAÇÃO_SYNAPSEOS: Chatwoot Mirror — reconciles a Chatwoot Account
# with a parsed ClientConfig YAML coming from the agentic side. Single
# source of truth lives on the agentic library; this service only "pulls"
# the projection into Chatwoot (Account name, AgentBots tagged with
# squadron_role, WhatsApp inbox provider/credentials drift detection).
#
# Two conservative choices, by design:
#   1. Inboxes are NEVER auto-created — operator runs the existing
#      Settings → Inboxes wizard. We only flag :inbox_missing drift.
#   2. AgentBots are NEVER deleted when removed from YAML — they may be
#      referenced by past conversations / inboxes. We soft-disable via
#      description prefix and surface :agent_bot_orphan drift.
# rubocop:disable Metrics/ClassLength -- coeso: três sync_* + drift detection num único componente.
class Synapseos::ChatwootMirror
  Result = Struct.new(:ok, :actions, :errors, keyword_init: true) do
    def ok?
      ok == true
    end
  end

  PROVIDER_MAP = {
    'avisa' => 'avisa',
    'waba' => 'whatsapp_cloud',
    'hyperflow' => 'hyperflow'
  }.freeze

  ACCOUNT_SLUG_KEY = 'synapseos_agentic_slug'
  ACCOUNT_ID_KEY = 'synapseos_agentic_account_id'

  def initialize(account:, client_yaml:)
    raise ArgumentError, 'account is required' if account.nil?
    raise ArgumentError, 'client_yaml must be a Hash' unless client_yaml.is_a?(Hash)

    @account = account
    @yaml = client_yaml.deep_stringify_keys
    @actions = []
    @errors = []
  end

  def sync_all
    @account.with_lock do
      sync_account_from_yaml
      sync_agent_bots
      sync_inbox
    end
    Result.new(ok: @errors.empty?, actions: @actions, errors: @errors)
  rescue StandardError => e
    Result.new(ok: false, actions: [], errors: [{ kind: :transaction_failed, message: e.message }])
  end

  # Updates Account#name and stores a durable pointer back to the agentic
  # ClientConfig slug. We use Account#custom_attributes (jsonb, no schema
  # validator) instead of Account#settings, since settings has a JSON
  # schema that would silently accept extra keys but is also actively used
  # by other features — keeping our pointer in custom_attributes avoids
  # any future schema collisions.
  def sync_account_from_yaml
    before_attrs = { name: @account.name, custom_attributes: @account.custom_attributes.dup }
    @account.custom_attributes ||= {}
    changed = apply_account_attrs

    return record_action(:account_unchanged, target: @account.id, status: :noop) unless changed

    @account.save!
    record_action(:account_updated, target: @account.id, before: before_attrs,
                                    after: { name: @account.name, custom_attributes: @account.custom_attributes.dup },
                                    status: :ok)
  end

  def sync_agent_bots
    desired = enabled_agents
    desired.each { |slug, cfg| upsert_agent_bot(slug, cfg) }
    flag_orphan_agent_bots(desired.keys)
  end

  def sync_inbox
    whatsapp = @yaml['whatsapp']
    return record_action(:inbox_skipped, target: nil, status: :noop, message: 'no whatsapp block in YAML') if whatsapp.blank?

    chatwoot_provider = PROVIDER_MAP[whatsapp['provider'].to_s]
    return record_error(:inbox_provider_unknown, "Unknown YAML provider: #{whatsapp['provider']}") unless chatwoot_provider

    channel = find_whatsapp_channel(chatwoot_provider, whatsapp)
    if channel.nil?
      # Conservative: do NOT auto-create. Inbox creation requires phone_number,
      # name, and binding to an Inbox row — the operator should use the existing
      # Settings → Inboxes wizard (or the action button surfaced by PR3+PR6).
      return record_action(:inbox_missing, target: chatwoot_provider, status: :drift,
                                           suggested_fix: 'create inbox via Settings → Inboxes wizard')
    end

    diff = credential_diff(channel, whatsapp)
    if diff.empty?
      record_action(:inbox_in_sync, target: channel.id, status: :ok)
    else
      # Don't auto-overwrite credentials — that's a destructive change for an
      # already-running channel. PR8 will route credential sync through a
      # dedicated agentic endpoint that the operator approves explicitly.
      record_action(:inbox_credential_mismatch, target: channel.id, status: :drift, diff: diff)
    end
  end

  def detect_drift
    drift = []
    drift.concat(account_name_drift)
    drift.concat(agent_bot_drift)
    drift.concat(inbox_drift)
    drift
  end

  private

  def enabled_agents
    raw = @yaml['agents']
    return {} unless raw.is_a?(Hash)

    raw.each_with_object({}) do |(slug, cfg), acc|
      next unless cfg.is_a?(Hash) && cfg['enabled']
      next unless AgentBot::SQUADRON_ROLES.include?(slug.to_s)

      acc[slug.to_s] = cfg
    end
  end

  def upsert_agent_bot(slug, cfg)
    bot = AgentBot.where(account_id: @account.id, squadron_role: slug).first_or_initialize
    before = bot.persisted? ? { name: bot.name, description: bot.description } : nil

    # Don't touch outgoing_url: an operator may have set it manually. PR8
    # will own credential/webhook URL syncing once that flow is designed.
    apply_agent_bot_attrs(bot, slug, cfg)

    persist_agent_bot(bot, slug, before)
  end

  # Stamps the desired in-memory attributes on the bot WITHOUT saving. We
  # deliberately overwrite description (even when the bot is currently
  # soft-disabled) so re-enabling a bot from YAML produces a normal dirty
  # diff that persist_agent_bot can record as :agent_bot_synced/:updated.
  # Saving here would clear dirty tracking and the audit trail would lose
  # the before/after snapshot.
  def apply_agent_bot_attrs(bot, slug, cfg)
    desired_name = cfg['persona_full'].to_s
    desired_description = "Synapse OS — #{slug.capitalize}"

    bot.name = desired_name if desired_name.present?
    bot.description = desired_description
    bot.account_id = @account.id
    bot.squadron_role = slug
  end

  def persist_agent_bot(bot, slug, before)
    return record_action(:agent_bot_synced, target: bot.id, status: :noop) unless bot.changed?

    status = bot.persisted? ? :updated : :created
    bot.save!
    record_action(:agent_bot_synced, target: bot.id, before: before,
                                     after: { name: bot.name, description: bot.description, squadron_role: slug },
                                     status: status)
  end

  def flag_orphan_agent_bots(desired_slugs)
    AgentBot.where(account_id: @account.id).where.not(squadron_role: nil).find_each do |bot|
      next if desired_slugs.include?(bot.squadron_role)
      next if bot.synapseos_disabled?

      bot.mark_synapseos_disabled!
      record_action(:agent_bot_disabled, target: bot.id, status: :drift,
                                         message: "agent #{bot.squadron_role} not in YAML; soft-disabled")
    end
  end

  def apply_account_attrs
    desired_name = @yaml['name'].to_s
    desired_slug = @yaml['slug'].to_s
    desired_aid  = @yaml['chatwoot_account_id']

    changed = false
    changed |= update_account_name(desired_name)
    changed |= update_account_attr(ACCOUNT_SLUG_KEY, desired_slug) if desired_slug.present?
    changed |= update_account_attr(ACCOUNT_ID_KEY, desired_aid) if desired_aid.present?
    changed
  end

  def update_account_name(desired)
    return false if desired.blank? || desired == @account.name

    @account.name = desired
    true
  end

  def update_account_attr(key, value)
    return false if @account.custom_attributes[key] == value

    @account.custom_attributes[key] = value
    true
  end

  def find_whatsapp_channel(chatwoot_provider, whatsapp)
    scope = Channel::Whatsapp.where(account_id: @account.id, provider: chatwoot_provider)
    return nil if scope.empty?

    desired_phone = whatsapp['phone_number'] || whatsapp.dig(whatsapp['provider'].to_s, 'phone_number')
    if desired_phone.present?
      match = scope.find_by(phone_number: desired_phone)
      return match if match
    end
    # Fall back to the single channel for the provider if there's exactly one.
    scope.count == 1 ? scope.first : nil
  end

  def credential_diff(channel, whatsapp)
    expected = expected_provider_config(whatsapp)
    actual = channel.provider_config || {}
    expected.each_with_object([]) do |(key, value), diff|
      diff << { key: key, expected: value, actual: actual[key] } if actual[key].to_s != value.to_s
    end
  end

  def expected_provider_config(whatsapp)
    case whatsapp['provider']
    when 'avisa'    then { 'base_url' => whatsapp.dig('avisa', 'base_url') }.compact
    when 'waba'     then whatsapp.fetch('waba', {}).slice('phone_number_id', 'business_account_id').compact
    when 'hyperflow' then whatsapp.fetch('hyperflow', {}).slice('n8n_webhook_url').compact
    else {}
    end
  end

  def account_name_drift
    desired = @yaml['name'].to_s
    return [] if desired.blank? || desired == @account.name

    [{ kind: :account_name_mismatch,
       message: "Account name '#{@account.name}' differs from YAML '#{desired}'",
       suggested_fix: 'run sync_all (or sync_account_from_yaml) to align' }]
  end

  def agent_bot_drift
    drift = []
    desired = enabled_agents.keys
    desired.each do |slug|
      next if AgentBot.exists?(account_id: @account.id, squadron_role: slug)

      drift << { kind: :agent_bot_missing,
                 message: "AgentBot for role #{slug} missing on account ##{@account.id}",
                 suggested_fix: 'run sync_agent_bots' }
    end
    AgentBot.where(account_id: @account.id).where.not(squadron_role: nil).pluck(:squadron_role).each do |slug|
      next if desired.include?(slug)

      drift << { kind: :agent_bot_orphan,
                 message: "AgentBot for role #{slug} exists but is not in YAML",
                 suggested_fix: 'remove from YAML or re-enable in YAML; bot is soft-disabled' }
    end
    drift
  end

  def inbox_drift
    whatsapp = @yaml['whatsapp']
    return [drift_no_whatsapp] if whatsapp.blank?

    chatwoot_provider = PROVIDER_MAP[whatsapp['provider'].to_s]
    return [drift_unknown_provider(whatsapp)] unless chatwoot_provider

    channel = find_whatsapp_channel(chatwoot_provider, whatsapp)
    return [drift_inbox_missing(chatwoot_provider)] if channel.nil?

    diff = credential_diff(channel, whatsapp)
    diff.empty? ? [] : [drift_credential_mismatch(channel, diff)]
  end

  def drift_no_whatsapp
    { kind: :no_whatsapp_config_in_yaml,
      message: "YAML for account ##{@account.id} has no whatsapp block",
      suggested_fix: 'add whatsapp section to ClientConfig YAML' }
  end

  def drift_unknown_provider(whatsapp)
    { kind: :inbox_provider_mismatch,
      message: "Unknown YAML provider: #{whatsapp['provider']}",
      suggested_fix: 'fix provider value (avisa | waba | hyperflow)' }
  end

  def drift_inbox_missing(chatwoot_provider)
    { kind: :inbox_missing,
      message: "No #{chatwoot_provider} channel found on account ##{@account.id}",
      suggested_fix: 'create inbox via Settings → Inboxes wizard' }
  end

  def drift_credential_mismatch(channel, diff)
    { kind: :inbox_credential_mismatch,
      message: "Channel ##{channel.id} provider_config differs from YAML on keys: #{diff.pluck(:key).join(', ')}",
      suggested_fix: 'reconcile credentials via PR8 sync flow' }
  end

  def record_action(kind, target:, status:, **extra)
    @actions << { kind: kind, target: target, status: status }.merge(extra)
  end

  def record_error(kind, message)
    @errors << { kind: kind, message: message }
  end
end
# rubocop:enable Metrics/ClassLength
