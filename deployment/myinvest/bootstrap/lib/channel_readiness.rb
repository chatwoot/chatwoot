# frozen_string_literal: true

require 'json'
require_relative '../../scripts/cutover-whatsapp'
require_relative 'whatsapp_cutover'

module Myinvest::ChannelReadiness
  class Builder
    CHANNELS = %w[email instagram whatsapp].freeze
    INSTAGRAM_PERMISSIONS = %w[instagram_manage_messages pages_manage_metadata pages_show_list].freeze
    DECIMAL_ID_REGEX = Myinvest::WhatsappCutover::HubspotChannelChecker::DECIMAL_ID_REGEX
    E164_REGEX = Myinvest::WhatsappCutover::Service::E164_REGEX

    def initialize(env)
      @env = env
    end

    def call
      canonical_tenants = parse_array(env.fetch('TENANTS_JSON'))
      configured_tenants = parse_array(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
      return invalid_configuration_report if configured_tenants.empty?

      @configured_tenants = configured_tenants
      duplicate_identities = duplicate_identities(configured_tenants)
      tenants = configured_tenants.map { |tenant| build_tenant(tenant, canonical_tenants, duplicate_identities) }

      {
        'version' => 1, 'dry_run' => true,
        'status' => tenants.all? { |tenant| tenant['status'] == 'ready' } ? 'ready' : 'blocked',
        'tenants' => tenants
      }
    rescue StandardError
      invalid_configuration_report
    end

    private

    attr_reader :env

    def parse_array(value)
      parsed = JSON.parse(value)
      raise TypeError unless parsed.is_a?(Array) && parsed.all? { |item| item.is_a?(Hash) }

      parsed
    end

    def build_tenant(tenant, canonical_tenants, duplicate_identities)
      key = tenant['key'].is_a?(String) ? tenant['key'] : ''
      mapping_valid = canonical_mapping_valid?(tenant, canonical_tenants)
      channels = CHANNELS.to_h do |channel|
        [channel, build_channel(channel, tenant[channel], tenant['account_id'], key, mapping_valid, duplicate_identities)]
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

      matches = canonical_tenants.select { |canonical| canonical['key'] == tenant['key'] }
      account_id = tenant['account_id'].to_s
      matches.one? && account_id == matches.first['accountId'].to_s &&
        canonical_tenants.count { |canonical| canonical['accountId'].to_s == account_id } == 1 &&
        @configured_tenants.count { |configured| configured['key'] == tenant['key'] } == 1 &&
        @configured_tenants.count { |configured| configured['account_id'].to_s == account_id } == 1
    end

    def build_channel(channel, config, tenant_account_id, tenant_key, mapping_valid, duplicate_identities)
      name = config.is_a?(Hash) && config['name'].is_a?(String) ? config['name'] : ''
      reasons = config.is_a?(Hash) ? send("#{channel}_reasons", config, tenant_key) : ['channel_configuration_missing']
      reasons.concat(common_channel_reasons(config, tenant_account_id)) if config.is_a?(Hash)
      reasons << 'public_name_missing' if name.empty?
      reasons << 'identity_duplicate' if duplicate_identities.include?([tenant_key, channel])
      reasons << 'tenant_mapping_invalid' unless mapping_valid
      reasons.uniq!
      human_reasons = reasons - %w[auto_reply_evaluation_unapproved bot_already_attached]
      {
        'name' => name,
        'human_status' => human_reasons.empty? ? 'ready' : 'blocked',
        'status' => reasons.empty? ? 'ready' : 'blocked',
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
      %w[
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
        ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
      ].all? { |key| present?(env[key]) }
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
              config['callback_count'] == 0 && config['hook_count'] == 0 && config['bot_attached'] == false &&
              config['auto_assignment_enabled'] == false
      inert ? [] : ['history_inbox_not_inert']
    end

    def email_reasons(config, _tenant_key)
      reasons = []
      reasons << 'mailbox_missing' unless present?(config['mailbox'])
      reasons << 'shared_mailbox_unconfirmed' unless config['dedicated_shared_mailbox_confirmed'] == true
      reasons << 'oauth_config_missing' unless present?(env['GOOGLE_OAUTH_CLIENT_ID']) && present?(env['GOOGLE_OAUTH_CLIENT_SECRET'])
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
        %w[business_id page_id account_id].each { |field| add_identity(occurrences, 'instagram', instagram[field], tenant_key) }
        %w[phone_number waba_id phone_number_id].each { |field| add_identity(occurrences, 'whatsapp', whatsapp[field], tenant_key) }
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
      present?(env_name) && present?(env[env_name])
    end

    def present?(value)
      !value.to_s.strip.empty?
    end

    def invalid_configuration_report
      { 'version' => 1, 'dry_run' => true, 'status' => 'blocked', 'reasons' => ['configuration_invalid'], 'tenants' => [] }
    end
  end
end
