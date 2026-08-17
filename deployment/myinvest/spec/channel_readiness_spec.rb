# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../bootstrap/lib/channel_readiness'

class ChannelReadinessSpec < Minitest::Test
  TENANTS = [
    { 'key' => 'saas', 'accountId' => 10 },
    { 'key' => 'new_academy', 'accountId' => 20 },
    { 'key' => 'legacy_academy', 'accountId' => 30 }
  ].freeze

  def test_reports_ready_channels_without_disclosing_sensitive_input
    env = complete_env
    report = Myinvest::ChannelReadiness::Builder.new(env).call
    json = JSON.generate(report)

    assert_equal 'ready', report.fetch('status')
    assert report.fetch('dry_run')
    assert_equal %w[email instagram whatsapp], report.fetch('tenants').first.fetch('channels').keys
    assert_equal(%w[ready ready ready], report.fetch('tenants').first.fetch('channels').values.map { |channel| channel.fetch('status') })
    assert_includes json, 'SaaS Support'
    sensitive_values(env).each { |value| refute_includes json, value }
  end

  def test_fails_closed_for_noncanonical_tenant_mapping
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['account_id'] = '99'
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_equal 'blocked', report.fetch('status')
    assert_equal ['tenant_mapping_invalid'], report.dig('tenants', 0, 'reasons')
    assert(report.dig('tenants', 0, 'channels').values.all? { |channel| channel.fetch('status') == 'blocked' })
  end

  def test_blocks_duplicate_identities_across_tenants
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    duplicate = Marshal.load(Marshal.dump(config.first))
    duplicate['key'] = 'new_academy'
    duplicate['account_id'] = '20'
    duplicate['email']['name'] = 'Academy Email'
    duplicate['instagram']['name'] = 'Academy Instagram'
    duplicate['whatsapp']['name'] = 'Academy WhatsApp'
    %w[email instagram whatsapp].each { |channel| duplicate[channel]['inbox_account_id'] = '20' }
    duplicate['whatsapp']['cutover_confirmation'] = 'cutover-whatsapp:new_academy:+491234567890'
    config << duplicate
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_equal 'blocked', report.fetch('status')
    assert_equal %w[identity_duplicate], report.dig('tenants', 0, 'channels', 'email', 'reasons')
    assert_equal %w[identity_duplicate], report.dig('tenants', 1, 'channels', 'whatsapp', 'reasons')
  end

  def test_blocks_missing_credentials_permissions_and_cutover_confirmation
    env = complete_env.merge(
      'GOOGLE_OAUTH_CLIENT_SECRET' => '',
      'IG_TOKEN' => '',
      'WA_SECRET' => '',
      'HUBSPOT_CUTOVER_CONFIRMED' => 'false'
    )

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_equal %w[oauth_config_missing], report.dig('tenants', 0, 'channels', 'email', 'reasons')
    assert_equal %w[token_missing], report.dig('tenants', 0, 'channels', 'instagram', 'reasons')
    assert_equal %w[app_secret_missing hubspot_cutover_unconfirmed], report.dig('tenants', 0, 'channels', 'whatsapp', 'reasons')
  end

  def test_blocks_unencrypted_credentials_incomplete_rosters_and_unverified_providers
    env = complete_env
    env['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'] = ''
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['email']['human_inbox_member_ids'] = ['7']
    config.first['instagram']['callback_verified'] = false
    config.first['whatsapp']['provider_health'] = 'degraded'
    config.first['history_inbox'] = {
      'inbox_account_id' => '10', 'human_inbox_member_ids' => %w[7 8], 'expected_human_inbox_member_ids' => %w[7 8],
      'callback_count' => 1, 'hook_count' => 0, 'bot_attached' => false, 'auto_assignment_enabled' => false
    }
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_includes report.dig('tenants', 0, 'channels', 'email', 'reasons'), 'credential_encryption_unconfigured'
    assert_includes report.dig('tenants', 0, 'channels', 'email', 'reasons'), 'human_roster_incomplete'
    assert_includes report.dig('tenants', 0, 'channels', 'instagram', 'reasons'), 'callback_unverified'
    assert_includes report.dig('tenants', 0, 'channels', 'whatsapp', 'reasons'), 'provider_health_unverified'
    assert_equal ['history_inbox_not_inert'], report.dig('tenants', 0, 'reasons')
  end

  def test_invalid_json_returns_a_redacted_fail_closed_report
    report = Myinvest::ChannelReadiness::Builder.new('TENANTS_JSON' => 'secret', 'CHANNEL_READINESS_CONFIG_JSON' => '{token').call

    assert_equal({ 'version' => 1, 'dry_run' => true, 'status' => 'blocked', 'reasons' => ['configuration_invalid'], 'tenants' => [] }, report)
  end

  def test_empty_manifest_is_blocked
    report = Myinvest::ChannelReadiness::Builder.new(
      'TENANTS_JSON' => JSON.generate(TENANTS), 'CHANNEL_READINESS_CONFIG_JSON' => '[]'
    ).call

    assert_equal 'blocked', report.fetch('status')
    assert_equal ['configuration_invalid'], report.fetch('reasons')
  end

  def test_reports_human_readiness_but_blocks_bot_attachment_without_reviewed_approval
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['instagram'].delete('auto_reply_evaluation_approved')
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call
    instagram = report.dig('tenants', 0, 'channels', 'instagram')

    assert_equal 'ready', instagram.fetch('human_status')
    assert_equal 'blocked', instagram.fetch('status')
    assert_equal ['auto_reply_evaluation_unapproved'], instagram.fetch('reasons')
  end

  private

  def complete_env
    config = [{
      'key' => 'saas',
      'account_id' => '10',
      'email' => {
        'name' => 'SaaS Support', 'mailbox' => 'support@example.invalid', 'dedicated_shared_mailbox_confirmed' => true,
        'inbox_account_id' => '10', 'human_inbox_member_ids' => %w[7 8], 'expected_human_inbox_member_ids' => %w[7 8],
        'provider_health' => 'ready', 'callback_verified' => true, 'bot_attached' => false,
        'auto_reply_evaluation_approved' => true
      },
      'instagram' => {
        'name' => 'SaaS Instagram', 'business_id' => '111', 'page_id' => '222', 'account_id' => '333',
        'access_token_env' => 'IG_TOKEN', 'permissions' => %w[instagram_manage_messages pages_manage_metadata pages_show_list],
        'inbox_account_id' => '10', 'human_inbox_member_ids' => %w[7 8], 'expected_human_inbox_member_ids' => %w[7 8],
        'provider_health' => 'ready', 'callback_verified' => true, 'bot_attached' => false,
        'auto_reply_evaluation_approved' => true
      },
      'whatsapp' => {
        'name' => 'SaaS WhatsApp', 'phone_number' => '+491234567890', 'waba_id' => '444', 'phone_number_id' => '555',
        'access_token_env' => 'WA_TOKEN', 'app_secret_env' => 'WA_SECRET', 'hubspot_owner' => 'HubSpot Support',
        'hubspot_channel_account_id' => '666', 'cutover_confirmation' => 'cutover-whatsapp:saas:+491234567890',
        'inbox_account_id' => '10', 'human_inbox_member_ids' => %w[7 8], 'expected_human_inbox_member_ids' => %w[7 8],
        'provider_health' => 'ready', 'callback_verified' => true, 'bot_attached' => false,
        'auto_reply_evaluation_approved' => true
      }
    }]
    {
      'TENANTS_JSON' => JSON.generate(TENANTS),
      'CHANNEL_READINESS_CONFIG_JSON' => JSON.generate(config),
      'GOOGLE_OAUTH_CLIENT_ID' => 'google-client-id',
      'GOOGLE_OAUTH_CLIENT_SECRET' => 'google-client-secret',
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary-encryption-key',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'deterministic-encryption-key',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'encryption-salt',
      'IG_TOKEN' => 'instagram-access-token',
      'WA_TOKEN' => 'whatsapp-access-token',
      'WA_SECRET' => 'whatsapp-app-secret',
      'HUBSPOT_CUTOVER_CONFIRMED' => 'true'
    }
  end

  def sensitive_values(env)
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON')).first
    [
      config.dig('email', 'mailbox'), config.dig('instagram', 'business_id'), config.dig('instagram', 'page_id'),
      config.dig('instagram', 'account_id'), config.dig('whatsapp', 'phone_number'), config.dig('whatsapp', 'waba_id'),
      config.dig('whatsapp', 'phone_number_id'), config.dig('whatsapp', 'hubspot_owner'),
      config.dig('whatsapp', 'hubspot_channel_account_id'), env['GOOGLE_OAUTH_CLIENT_ID'], env['GOOGLE_OAUTH_CLIENT_SECRET'],
      env['IG_TOKEN'], env['WA_TOKEN'], env['WA_SECRET']
    ]
  end
end
