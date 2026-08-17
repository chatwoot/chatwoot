# frozen_string_literal: true

require 'json'
require_relative '../../scripts/cutover-whatsapp'
require_relative 'whatsapp_cutover'

module Myinvest::ChannelReadiness
  class ManifestError < StandardError; end

  # This standalone validator keeps the fail-closed manifest contract explicit and auditable in one place.
  # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
  class Builder
    CHANNELS = %w[email instagram whatsapp].freeze
    TENANT_KEYS = %w[saas new_academy legacy_academy].freeze
    INSTAGRAM_PERMISSIONS = %w[instagram_manage_messages pages_manage_metadata pages_show_list].freeze
    INSTAGRAM_IDENTITY_FIELDS = %w[business_id page_id account_id].freeze
    WHATSAPP_IDENTITY_FIELDS = %w[phone_number waba_id phone_number_id].freeze
    DECIMAL_ID_REGEX = Myinvest::WhatsappCutover::HubspotChannelChecker::DECIMAL_ID_REGEX
    E164_REGEX = Myinvest::WhatsappCutover::Service::E164_REGEX
    CREDENTIAL_ENV_REGEX = /\ACHANNEL_READINESS_[A-Z0-9_]+\z/
    ENCRYPTION_CONFIGURED_MARKER = 'CHANNEL_READINESS_ENCRYPTION_CONFIGURED'
    GOOGLE_OAUTH_CONFIGURED_MARKER = 'GOOGLE_OAUTH_CONFIGURED'
    RESERVED_READINESS_ENV_NAMES = [
      'CHANNEL_READINESS_CONFIG_JSON', ENCRYPTION_CONFIGURED_MARKER, GOOGLE_OAUTH_CONFIGURED_MARKER
    ].freeze
    FORBIDDEN_SECRET_ENV_NAMES = %w[
      ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
      ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
      ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
      GOOGLE_OAUTH_CLIENT_ID
      GOOGLE_OAUTH_CLIENT_SECRET
    ].freeze
    FORBIDDEN_ENV_PREFIXES = %w[
      POSTGRES_ADMIN_ MINIO_ROOT_ ADMIN_ ANTHROPIC_ AWS_ BACKUP_ CLAUDE_AGENT_DATABASE
    ].freeze

    def initialize(env)
      @env = env
    end

    def call
      canonical_tenants = parse_array(env.fetch('TENANTS_JSON'))
      configured_tenants = parse_array(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
      return invalid_configuration_report if configured_tenants.empty?

      return invalid_configuration_report('tenant_mapping_invalid') unless exact_tenant_set?(canonical_tenants, configured_tenants)

      credential_env_names
      duplicate_identities = duplicate_identities(configured_tenants)
      tenants = configured_tenants.map { |tenant| build_tenant(tenant, canonical_tenants, duplicate_identities) }

      {
        'version' => 1, 'dry_run' => true, 'assessment' => 'declarative',
        'status' => tenants.all? { |tenant| tenant['status'] == 'ready' } ? 'ready' : 'blocked',
        'tenants' => tenants
      }
    rescue StandardError
      invalid_configuration_report
    end

    def credential_env_names
      raise ManifestError if forbidden_environment?

      canonical_tenants = parse_array(env.fetch('TENANTS_JSON'))
      configured_tenants = parse_array(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
      raise ManifestError unless exact_tenant_set?(canonical_tenants, configured_tenants) &&
                                 configured_tenants.all? { |tenant| valid_tenant_manifest?(tenant) }

      names = configured_tenants.flat_map do |tenant|
        [tenant.dig('instagram', 'access_token_env'), tenant.dig('whatsapp', 'access_token_env'),
         tenant.dig('whatsapp', 'app_secret_env')]
      end
      raise ManifestError unless names.all? { |name| valid_credential_env_name?(name) }

      names.uniq.sort
    rescue KeyError, JSON::ParserError, TypeError
      raise ManifestError
    end

    private

    attr_reader :env

    def parse_array(value)
      parsed = JSON.parse(value)
      raise TypeError unless parsed.is_a?(Array) && parsed.all?(Hash)

      parsed
    end

    def build_tenant(tenant, canonical_tenants, duplicate_identities)
      key = tenant['key'].is_a?(String) ? tenant['key'] : ''
      mapping_valid = canonical_mapping_valid?(tenant, canonical_tenants)
      channels = {}
      CHANNELS.each do |channel|
        channels[channel] = build_channel(channel, tenant[channel], tenant['account_id'], key, mapping_valid, duplicate_identities)
      end
      reasons = mapping_valid ? history_inbox_reasons(tenant['history_inbox'], tenant['account_id']) : ['tenant_mapping_invalid']
      {
        'key' => key,
        'status' => reasons.empty? && channels.values.all? { |channel| channel['status'] == 'ready' } ? 'ready' : 'blocked',
        'reasons' => reasons,
        'channels' => channels
      }
    end

    def canonical_mapping_valid?(tenant, canonical_tenants)
      return false unless tenant['key'].is_a?(String)

      canonical = canonical_tenants.find { |candidate| candidate['key'] == tenant['key'] }
      canonical && tenant['account_id'].to_s == canonical['accountId'].to_s
    end

    def exact_tenant_set?(canonical_tenants, configured_tenants)
      canonical = tenant_pairs(canonical_tenants, 'accountId')
      configured = tenant_pairs(configured_tenants, 'account_id')
      canonical && configured && canonical == configured
    end

    def tenant_pairs(tenants, account_id_key)
      return unless tenants.length == TENANT_KEYS.length
      return unless tenants.all? do |tenant|
        tenant['key'].is_a?(String) && tenant[account_id_key].to_s.match?(DECIMAL_ID_REGEX)
      end

      pairs = tenants.map { |tenant| [tenant['key'], tenant[account_id_key].to_s] }
      return unless pairs.map(&:first).sort == TENANT_KEYS.sort
      return unless pairs.map(&:last).uniq.length == TENANT_KEYS.length

      pairs.sort
    end

    def valid_tenant_manifest?(tenant)
      tenant_keys = %w[key account_id email instagram whatsapp history_inbox]
      return false unless allowed_keys?(tenant, tenant_keys) && CHANNELS.all? { |channel| valid_common_manifest?(tenant[channel]) }

      email = tenant['email']
      instagram = tenant['instagram']
      whatsapp = tenant['whatsapp']
      common_keys = %w[name inbox_account_id human_inbox_member_ids expected_human_inbox_member_ids provider_health
                       callback_verified bot_attached auto_reply_evaluation_approved]
      email_valid = allowed_keys?(email, common_keys + %w[mailbox dedicated_shared_mailbox_confirmed]) &&
                    email['mailbox'].is_a?(String) && boolean?(email['dedicated_shared_mailbox_confirmed'])
      instagram_valid = allowed_keys?(instagram, common_keys + %w[business_id page_id account_id access_token_env permissions]) &&
                        %w[business_id page_id account_id access_token_env].all? { |field| instagram[field].is_a?(String) } &&
                        instagram['permissions'].is_a?(Array) && instagram['permissions'].all?(String)
      whatsapp_valid = allowed_keys?(
        whatsapp,
        common_keys + %w[phone_number waba_id phone_number_id access_token_env app_secret_env hubspot_owner
                         hubspot_channel_account_id cutover_confirmation]
      ) &&
                       %w[phone_number waba_id phone_number_id access_token_env app_secret_env hubspot_owner
                          hubspot_channel_account_id cutover_confirmation].all? { |field| whatsapp[field].is_a?(String) }
      email_valid && instagram_valid && whatsapp_valid && valid_history_manifest?(tenant['history_inbox'])
    end

    def valid_common_manifest?(config)
      config.is_a?(Hash) && config['name'].is_a?(String) && config['inbox_account_id'].to_s.match?(DECIMAL_ID_REGEX) &&
        config['human_inbox_member_ids'].is_a?(Array) && config['expected_human_inbox_member_ids'].is_a?(Array) &&
        config['provider_health'].is_a?(String) && boolean?(config['callback_verified']) &&
        boolean?(config['bot_attached']) &&
        (!config.key?('auto_reply_evaluation_approved') || boolean?(config['auto_reply_evaluation_approved']))
    end

    def boolean?(value)
      value == true || value == false
    end

    def valid_history_manifest?(config)
      return true if config.nil?

      keys = %w[inbox_account_id human_inbox_member_ids expected_human_inbox_member_ids callback_count hook_count
                bot_attached auto_assignment_enabled]
      allowed_keys?(config, keys) && config['callback_count'].is_a?(Integer) && config['hook_count'].is_a?(Integer) &&
        boolean?(config['bot_attached']) && boolean?(config['auto_assignment_enabled']) && exact_human_roster?(config)
    end

    def allowed_keys?(hash, keys)
      hash.is_a?(Hash) && (hash.keys - keys).empty?
    end

    def build_channel(channel, config, tenant_account_id, tenant_key, mapping_valid, duplicate_identities)
      name = config.is_a?(Hash) && config['name'].is_a?(String) ? config['name'] : ''
      reasons = config.is_a?(Hash) ? send("#{channel}_reasons", config, tenant_key) : ['channel_configuration_missing']
      reasons.concat(common_channel_reasons(config, tenant_account_id)) if config.is_a?(Hash)
      reasons << 'public_name_missing' if name.empty?
      reasons << 'identity_duplicate' if duplicate_identities.include?([tenant_key, channel])
      reasons << 'tenant_mapping_invalid' unless mapping_valid
      reasons << 'runtime_verification_required'
      reasons.uniq!
      human_reasons = reasons - %w[auto_reply_evaluation_unapproved bot_already_attached runtime_verification_required]
      {
        'name' => name,
        'human_status' => human_reasons.empty? ? 'planned' : 'blocked',
        'status' => 'blocked',
        'reasons' => reasons
      }
    end

    def common_channel_reasons(config, tenant_account_id)
      reasons = []
      reasons << 'credential_encryption_unconfigured' unless encryption_configured?
      reasons << 'inbox_ownership_invalid' unless config['inbox_account_id'].to_s == tenant_account_id.to_s
      reasons << 'human_roster_incomplete' unless exact_human_roster?(config)
      reasons << 'provider_health_unverified' unless config['provider_health'] == 'ready'
      reasons << 'callback_unverified' unless config['callback_verified'] == true
      reasons << 'bot_already_attached' unless config['bot_attached'] == false
      reasons << 'auto_reply_evaluation_unapproved' unless config['auto_reply_evaluation_approved'] == true
      reasons
    end

    def encryption_configured?
      env[ENCRYPTION_CONFIGURED_MARKER] == 'true'
    end

    def exact_human_roster?(config)
      actual = config['human_inbox_member_ids']
      expected = config['expected_human_inbox_member_ids']
      actual.is_a?(Array) && expected.is_a?(Array) && expected.any? && actual.uniq.sort == expected.uniq.sort
    end

    def history_inbox_reasons(config, tenant_account_id)
      return [] if config.nil?
      return ['history_inbox_not_inert'] unless config.is_a?(Hash)

      inert = config['inbox_account_id'].to_s == tenant_account_id.to_s && exact_human_roster?(config) &&
              config['callback_count'].zero? && config['hook_count'].zero? && config['bot_attached'] == false &&
              config['auto_assignment_enabled'] == false
      inert ? [] : ['history_inbox_not_inert']
    end

    def email_reasons(config, _tenant_key)
      reasons = []
      reasons << 'mailbox_missing' unless present?(config['mailbox'])
      reasons << 'shared_mailbox_unconfirmed' unless config['dedicated_shared_mailbox_confirmed'] == true
      reasons << 'oauth_config_missing' unless env[GOOGLE_OAUTH_CONFIGURED_MARKER] == 'true'
      reasons
    end

    def instagram_reasons(config, _tenant_key)
      reasons = []
      reasons << 'business_id_invalid' unless decimal_id?(config['business_id'])
      reasons << 'page_id_invalid' unless decimal_id?(config['page_id'])
      reasons << 'account_id_invalid' unless decimal_id?(config['account_id'])
      reasons << 'token_missing' unless credential_present?(config['access_token_env'])
      permissions = config['permissions']
      reasons << 'permissions_missing' unless permissions.is_a?(Array) && (INSTAGRAM_PERMISSIONS - permissions).empty?
      reasons
    end

    def whatsapp_reasons(config, tenant_key)
      reasons = []
      phone_number = config['phone_number'].to_s
      reasons << 'phone_number_invalid' unless phone_number.match?(E164_REGEX)
      reasons << 'waba_id_invalid' unless decimal_id?(config['waba_id'])
      reasons << 'phone_number_id_invalid' unless decimal_id?(config['phone_number_id'])
      reasons << 'token_missing' unless credential_present?(config['access_token_env'])
      reasons << 'app_secret_missing' unless credential_present?(config['app_secret_env'])
      reasons << 'hubspot_owner_missing' unless present?(config['hubspot_owner'])
      reasons << 'hubspot_channel_account_id_invalid' unless decimal_id?(config['hubspot_channel_account_id'])
      confirmed = env['HUBSPOT_CUTOVER_CONFIRMED'] == 'true' && cutover_confirmation_valid?(config, tenant_key)
      reasons << 'hubspot_cutover_unconfirmed' unless confirmed
      reasons
    end

    def cutover_confirmation_valid?(config, tenant_key)
      cutover_env = {
        'CUTOVER_TENANT' => tenant_key,
        'WHATSAPP_PHONE_NUMBER' => config['phone_number'],
        'CUTOVER_CONFIRMATION' => config['cutover_confirmation']
      }
      Myinvest::WhatsappCutover::Wrapper.new(cutover_env).send(:validate_confirmation!)
      true
    rescue RuntimeError
      false
    end

    def duplicate_identities(tenants)
      occurrences = Hash.new { |hash, key| hash[key] = [] }
      tenants.each do |tenant|
        tenant_key = tenant['key'].is_a?(String) ? tenant['key'] : ''
        email = channel_config(tenant, 'email')
        instagram = channel_config(tenant, 'instagram')
        whatsapp = channel_config(tenant, 'whatsapp')
        mailbox = email['mailbox']
        add_identity(occurrences, 'email', mailbox.downcase, tenant_key) if mailbox.is_a?(String)
        INSTAGRAM_IDENTITY_FIELDS.each { |field| add_identity(occurrences, 'instagram', instagram[field], tenant_key) }
        WHATSAPP_IDENTITY_FIELDS.each { |field| add_identity(occurrences, 'whatsapp', whatsapp[field], tenant_key) }
      end
      occurrences.each_with_object([]) do |((channel, _identity), tenant_keys), duplicates|
        next unless tenant_keys.uniq.length > 1

        tenant_keys.each { |key| duplicates << [key, channel] }
      end
    end

    def add_identity(occurrences, channel, identity, tenant_key)
      occurrences[[channel, identity]] << tenant_key if present?(identity)
    end

    def channel_config(tenant, channel)
      tenant[channel].is_a?(Hash) ? tenant[channel] : {}
    end

    def decimal_id?(value)
      value.is_a?(String) && value.match?(DECIMAL_ID_REGEX)
    end

    def credential_present?(env_name)
      present?(env_name) && env[env_name] == 'true'
    end

    def valid_credential_env_name?(name)
      name.is_a?(String) && name.match?(CREDENTIAL_ENV_REGEX) && RESERVED_READINESS_ENV_NAMES.none?(name)
    end

    def forbidden_environment?
      env.keys.any? do |key|
        FORBIDDEN_SECRET_ENV_NAMES.include?(key.to_s) || FORBIDDEN_ENV_PREFIXES.any? { |prefix| key.to_s.start_with?(prefix) }
      end
    end

    def present?(value)
      !value.to_s.strip.empty?
    end

    def invalid_configuration_report(reason = 'configuration_invalid')
      {
        'version' => 1, 'dry_run' => true, 'assessment' => 'declarative', 'status' => 'blocked',
        'reasons' => [reason], 'tenants' => []
      }
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
end
