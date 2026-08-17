# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require_relative '../bootstrap/lib/channel_readiness'

# This integration-style Minitest contract keeps complete manifests and wrapper assertions together for auditability.
# rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/MethodLength
class ChannelReadinessSpec < Minitest::Test
  TENANTS = [
    { 'key' => 'saas', 'accountId' => 10 },
    { 'key' => 'new_academy', 'accountId' => 20 },
    { 'key' => 'legacy_academy', 'accountId' => 30 }
  ].freeze

  def test_reports_declarative_channels_as_planned_and_runtime_blocked_without_disclosing_sensitive_input
    env = complete_env
    report = Myinvest::ChannelReadiness::Builder.new(env).call
    json = JSON.generate(report)

    assert_equal 'blocked', report.fetch('status')
    assert_equal 'declarative', report.fetch('assessment')
    assert report.fetch('dry_run')
    assert_equal %w[saas new_academy legacy_academy], (report.fetch('tenants').map { |tenant| tenant.fetch('key') })
    assert_equal %w[email instagram whatsapp], report.fetch('tenants').first.fetch('channels').keys
    assert_equal(%w[planned planned planned],
                 report.fetch('tenants').first.fetch('channels').values.map { |channel| channel.fetch('human_status') })
    assert_equal(%w[blocked blocked blocked],
                 report.fetch('tenants').first.fetch('channels').values.map { |channel| channel.fetch('status') })
    assert report.fetch('tenants').first.fetch('channels').values.all? do |channel|
      channel.fetch('reasons').include?('runtime_verification_required')
    end
    assert_includes json, 'saas Support'
    sensitive_values(env).each { |value| refute_includes json, value }
  end

  def test_fails_closed_for_noncanonical_tenant_mapping
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['account_id'] = '99'
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_equal 'blocked', report.fetch('status')
    assert_equal ['tenant_mapping_invalid'], report.fetch('reasons')
    assert_empty report.fetch('tenants')
  end

  def test_blocks_duplicate_identities_across_tenants
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config[1]['email']['mailbox'] = config[0]['email']['mailbox']
    %w[business_id page_id account_id].each do |field|
      config[1]['instagram'][field] = config[0]['instagram'][field]
    end
    %w[phone_number waba_id phone_number_id].each do |field|
      config[1]['whatsapp'][field] = config[0]['whatsapp'][field]
    end
    config[1]['whatsapp']['cutover_confirmation'] = "cutover-whatsapp:new_academy:#{config[0]['whatsapp']['phone_number']}"
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_equal 'blocked', report.fetch('status')
    assert_includes report.dig('tenants', 0, 'channels', 'email', 'reasons'), 'identity_duplicate'
    assert_includes report.dig('tenants', 1, 'channels', 'whatsapp', 'reasons'), 'identity_duplicate'
  end

  def test_blocks_missing_credentials_permissions_and_cutover_confirmation
    env = complete_env.merge(
      'GOOGLE_OAUTH_CONFIGURED' => '',
      'CHANNEL_READINESS_IG_TOKEN' => '',
      'CHANNEL_READINESS_WA_SECRET' => '',
      'HUBSPOT_CUTOVER_CONFIRMED' => 'false'
    )

    report = Myinvest::ChannelReadiness::Builder.new(env).call

    assert_includes report.dig('tenants', 0, 'channels', 'email', 'reasons'), 'oauth_config_missing'
    assert_includes report.dig('tenants', 0, 'channels', 'instagram', 'reasons'), 'token_missing'
    assert_includes report.dig('tenants', 0, 'channels', 'whatsapp', 'reasons'), 'app_secret_missing'
    assert_includes report.dig('tenants', 0, 'channels', 'whatsapp', 'reasons'), 'hubspot_cutover_unconfirmed'
  end

  def test_blocks_unencrypted_credentials_incomplete_rosters_and_unverified_providers
    env = complete_env
    env['CHANNEL_READINESS_ENCRYPTION_CONFIGURED'] = ''
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

    assert_equal(
      {
        'version' => 1, 'dry_run' => true, 'assessment' => 'declarative', 'status' => 'blocked',
        'reasons' => ['configuration_invalid'], 'tenants' => []
      },
      report
    )
  end

  def test_empty_manifest_is_blocked
    report = Myinvest::ChannelReadiness::Builder.new(
      'TENANTS_JSON' => JSON.generate(TENANTS), 'CHANNEL_READINESS_CONFIG_JSON' => '[]'
    ).call

    assert_equal 'blocked', report.fetch('status')
    assert_equal ['configuration_invalid'], report.fetch('reasons')
  end

  def test_credential_names_require_exact_canonical_tenant_set_and_readiness_namespace
    env = complete_env
    builder = Myinvest::ChannelReadiness::Builder.new(env)

    assert_equal %w[CHANNEL_READINESS_IG_TOKEN CHANNEL_READINESS_WA_SECRET CHANNEL_READINESS_WA_TOKEN],
                 builder.credential_env_names

    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['instagram']['access_token_env'] = 'ADMIN_PASSWORD'
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end

    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['instagram']['access_token_env'] = 'CHANNEL_READINESS_ENCRYPTION_CONFIGURED'
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end

    env = complete_env.merge('POSTGRES_ADMIN_PASSWORD' => 'must-not-enter-container')
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end

    env = complete_env.merge('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'must-not-enter-container')
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end

    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['instagram']['embedded_secret'] = 'must-not-pass'
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end

    env = complete_env
    env['TENANTS_JSON'] = JSON.generate(TENANTS.first(2))
    assert_raises(Myinvest::ChannelReadiness::ManifestError) do
      Myinvest::ChannelReadiness::Builder.new(env).credential_env_names
    end
  end

  def test_rejects_one_two_and_extra_tenant_even_when_both_manifests_match
    base_env = complete_env
    base_config = JSON.parse(base_env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    extra_tenant = { 'key' => 'extra_academy', 'accountId' => 40 }
    extra_config = Marshal.load(Marshal.dump(base_config.first))
    extra_config['key'] = 'extra_academy'
    extra_config['account_id'] = '40'
    cases = [
      [TENANTS.first(1), base_config.first(1)],
      [TENANTS.first(2), base_config.first(2)],
      [TENANTS + [extra_tenant], base_config + [extra_config]]
    ]

    cases.each do |canonical, configured|
      env = base_env.merge('TENANTS_JSON' => JSON.generate(canonical),
                           'CHANNEL_READINESS_CONFIG_JSON' => JSON.generate(configured))
      report = Myinvest::ChannelReadiness::Builder.new(env).call

      assert_equal 'blocked', report.fetch('status')
      assert_equal ['tenant_mapping_invalid'], report.fetch('reasons')
      assert_empty report.fetch('tenants')
    end
  end

  def test_rejects_duplicate_tenant_keys_and_account_ids_in_either_manifest
    base_env = complete_env
    base_config = JSON.parse(base_env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    canonical_duplicate_key = Marshal.load(Marshal.dump(TENANTS))
    canonical_duplicate_key[2]['key'] = 'saas'
    configured_duplicate_key = Marshal.load(Marshal.dump(base_config))
    configured_duplicate_key[2]['key'] = 'saas'
    canonical_duplicate_account = Marshal.load(Marshal.dump(TENANTS))
    canonical_duplicate_account[2]['accountId'] = 10
    configured_duplicate_account = Marshal.load(Marshal.dump(base_config))
    configured_duplicate_account[2]['account_id'] = '10'

    [
      [canonical_duplicate_key, base_config], [TENANTS, configured_duplicate_key],
      [canonical_duplicate_account, base_config], [TENANTS, configured_duplicate_account]
    ].each do |canonical, configured|
      env = base_env.merge('TENANTS_JSON' => JSON.generate(canonical),
                           'CHANNEL_READINESS_CONFIG_JSON' => JSON.generate(configured))
      report = Myinvest::ChannelReadiness::Builder.new(env).call

      assert_equal 'blocked', report.fetch('status')
      assert_equal ['tenant_mapping_invalid'], report.fetch('reasons')
      assert_empty report.fetch('tenants')
    end
  end

  def test_reports_human_readiness_but_blocks_bot_attachment_without_reviewed_approval
    env = complete_env
    config = JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON'))
    config.first['instagram'].delete('auto_reply_evaluation_approved')
    env['CHANNEL_READINESS_CONFIG_JSON'] = JSON.generate(config)

    report = Myinvest::ChannelReadiness::Builder.new(env).call
    instagram = report.dig('tenants', 0, 'channels', 'instagram')

    assert_equal 'planned', instagram.fetch('human_status')
    assert_equal 'blocked', instagram.fetch('status')
    assert_equal %w[auto_reply_evaluation_unapproved runtime_verification_required], instagram.fetch('reasons')
  end

  def test_executable_uses_dedicated_compose_service_without_putting_dynamic_credentials_on_argv
    Dir.mktmpdir do |directory|
      env_path = File.join(directory, '.env')
      fake_docker = File.join(directory, 'docker')
      File.write(env_path, <<~ENV)
        TENANTS_JSON='[{"key":"saas","accountId":10}]'
        CHANNEL_READINESS_CONFIG_JSON='[{"key":"saas","instagram":{"access_token_env":"CHANNEL_READINESS_IG_TOKEN"}}]'
        CHANNEL_READINESS_IG_TOKEN=dynamic-instagram-secret
        CHANNEL_READINESS_UNUSED_TOKEN=unreferenced-readiness-secret
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=readiness-primary-key
        ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=readiness-deterministic-key
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=readiness-key-derivation-salt
        GOOGLE_OAUTH_CLIENT_ID=readiness-google-client
        GOOGLE_OAUTH_CLIENT_SECRET=readiness-google-secret
        HUBSPOT_CUTOVER_CONFIRMED=true
        ADMIN_PASSWORD=admin-secret
        POSTGRES_ADMIN_PASSWORD=postgres-admin-secret
        MINIO_ROOT_PASSWORD=minio-root-secret
        ANTHROPIC_API_KEY=anthropic-secret
        AWS_SECRET_ACCESS_KEY=aws-secret
        BACKUP_GPG_RECIPIENT=backup-secret
        CLAUDE_AGENT_DATABASE_PASSWORD=agent-db-secret
      ENV
      File.write(fake_docker, <<~SH)
        #!/usr/bin/env sh
        set -eu
        arguments="$*"
        case " $arguments " in
          *" channel-readiness ruby "*) ;;
          *) exit 1 ;;
        esac
        for secret_value in dynamic-instagram-secret readiness-primary-key readiness-deterministic-key \
          readiness-key-derivation-salt readiness-google-client readiness-google-secret unreferenced-readiness-secret; do
          case "$arguments" in
            *"$secret_value"*) exit 1 ;;
          esac
        done
        count_file="$FAKE_STATE/count"
        count=0
        [ ! -f "$count_file" ] || count="$(cat "$count_file")"
        count=$((count + 1))
        printf '%s\n' "$count" > "$count_file"
        selected_env=
        work_dir=
        previous=
        for argument in "$@"; do
          [ "$previous" != --env-from-file ] || selected_env="$argument"
          case "$argument" in
            *:/readiness-work) work_dir="${argument%:/readiness-work}" ;;
          esac
          previous="$argument"
        done
        [ "$selected_env" != "$ENV_FILE" ]
        [ "$(stat -c %a "$selected_env")" = 600 ]
        for forbidden in ADMIN_PASSWORD POSTGRES_ADMIN_PASSWORD MINIO_ROOT_PASSWORD ANTHROPIC_API_KEY \
          AWS_SECRET_ACCESS_KEY BACKUP_GPG_RECIPIENT CLAUDE_AGENT_DATABASE_PASSWORD \
          ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY \
          ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET; do
          ! grep -q "^$forbidden=" "$selected_env"
        done
        for secret_value in dynamic-instagram-secret readiness-primary-key readiness-deterministic-key \
          readiness-key-derivation-salt readiness-google-client readiness-google-secret unreferenced-readiness-secret; do
          ! grep -Fq "$secret_value" "$selected_env"
        done
        ! grep -q '^CHANNEL_READINESS_UNUSED_TOKEN=' "$selected_env"
        if [ "$count" -eq 1 ]; then
          grep -q '^TENANTS_JSON=' "$selected_env"
          grep -q '^CHANNEL_READINESS_CONFIG_JSON=' "$selected_env"
          ! grep -q '^CHANNEL_READINESS_ENCRYPTION_CONFIGURED=' "$selected_env"
          ! grep -q '^GOOGLE_OAUTH_CONFIGURED=' "$selected_env"
          ! grep -q '^HUBSPOT_CUTOVER_CONFIRMED=' "$selected_env"
          printf '%s\n' CHANNEL_READINESS_IG_TOKEN > "$work_dir/credential-env-names"
          chmod 600 "$work_dir/credential-env-names"
        else
          grep -q '^CHANNEL_READINESS_IG_TOKEN=true$' "$selected_env"
          grep -q '^CHANNEL_READINESS_ENCRYPTION_CONFIGURED=true$' "$selected_env"
          grep -q '^GOOGLE_OAUTH_CONFIGURED=true$' "$selected_env"
          grep -q '^HUBSPOT_CUTOVER_CONFIRMED=true$' "$selected_env"
          printf '%s\n' '{"version":1,"dry_run":true,"status":"blocked","tenants":[]}'
        fi
      SH
      File.chmod(0o755, fake_docker)

      script = File.expand_path('../scripts/channel-readiness.rb', __dir__)
      stdout, stderr, status = Open3.capture3(
        {
          'PATH' => "#{directory}:#{ENV.fetch('PATH')}", 'ENV_FILE' => env_path,
          'FAKE_STATE' => directory, 'TMPDIR' => directory
        }, script
      )

      assert status.success?, stderr
      assert_equal({ 'version' => 1, 'dry_run' => true, 'status' => 'blocked', 'tenants' => [] }, JSON.parse(stdout))
      %w[
        dynamic-instagram-secret readiness-primary-key readiness-deterministic-key
        readiness-key-derivation-salt readiness-google-client readiness-google-secret unreferenced-readiness-secret
      ].each do |secret|
        refute_includes stdout, secret
        refute_includes stderr, secret
      end
      assert_empty Dir.glob(File.join(directory, 'channel-readiness.*'))
    end
  end

  def test_executable_fails_closed_before_starting_a_container_for_invalid_secret_assignments
    Dir.mktmpdir do |directory|
      env_path = File.join(directory, '.env')
      fake_docker = File.join(directory, 'docker')
      invoked = File.join(directory, 'docker-invoked')
      valid_env = <<~ENV
        TENANTS_JSON='[{"key":"saas","accountId":10},{"key":"new_academy","accountId":20},{"key":"legacy_academy","accountId":30}]'
        CHANNEL_READINESS_CONFIG_JSON='[]'
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=readiness-primary-key
        ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=readiness-deterministic-key
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=readiness-key-derivation-salt
        GOOGLE_OAUTH_CLIENT_ID=readiness-google-client
        GOOGLE_OAUTH_CLIENT_SECRET=readiness-google-secret
      ENV
      File.write(fake_docker, <<~SH)
        #!/usr/bin/env sh
        : > "$FAKE_DOCKER_INVOKED"
        exit 99
      SH
      File.chmod(0o755, fake_docker)
      invalid_envs = [
        valid_env.sub('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=readiness-primary-key', 'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY='),
        "#{valid_env}ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=duplicate\n",
        valid_env.sub("GOOGLE_OAUTH_CLIENT_SECRET=readiness-google-secret\n", ''),
        "#{valid_env}GOOGLE_OAUTH_CLIENT_SECRET=duplicate\n"
      ]
      script = File.expand_path('../scripts/channel-readiness.rb', __dir__)

      invalid_envs.each do |invalid_env|
        File.write(env_path, invalid_env)
        FileUtils.rm_f(invoked)
        stdout, stderr, status = Open3.capture3(
          {
            'PATH' => "#{directory}:#{ENV.fetch('PATH')}", 'ENV_FILE' => env_path,
            'FAKE_DOCKER_INVOKED' => invoked, 'TMPDIR' => directory
          }, script
        )

        refute status.success?
        assert_empty stdout
        assert_equal "Channel readiness environment is invalid.\n", stderr
        refute File.exist?(invoked)
      end
    end
  end

  private

  def complete_env
    config = TENANTS.each_with_index.map do |tenant, index|
      key = tenant.fetch('key')
      account_id = tenant.fetch('accountId').to_s
      phone_number = "+49123456789#{index}"
      common = {
        'inbox_account_id' => account_id, 'human_inbox_member_ids' => %w[7 8],
        'expected_human_inbox_member_ids' => %w[7 8], 'provider_health' => 'ready',
        'callback_verified' => true, 'bot_attached' => false, 'auto_reply_evaluation_approved' => true
      }
      {
        'key' => key, 'account_id' => account_id,
        'email' => common.merge(
          'name' => "#{key} Support", 'mailbox' => "support-#{key}@example.invalid",
          'dedicated_shared_mailbox_confirmed' => true
        ),
        'instagram' => common.merge(
          'name' => "#{key} Instagram", 'business_id' => (111 + index).to_s, 'page_id' => (222 + index).to_s,
          'account_id' => (333 + index).to_s, 'access_token_env' => 'CHANNEL_READINESS_IG_TOKEN',
          'permissions' => %w[instagram_manage_messages pages_manage_metadata pages_show_list]
        ),
        'whatsapp' => common.merge(
          'name' => "#{key} WhatsApp", 'phone_number' => phone_number, 'waba_id' => (444 + index).to_s,
          'phone_number_id' => (555 + index).to_s, 'access_token_env' => 'CHANNEL_READINESS_WA_TOKEN',
          'app_secret_env' => 'CHANNEL_READINESS_WA_SECRET', 'hubspot_owner' => "#{key} HubSpot Support",
          'hubspot_channel_account_id' => (666 + index).to_s,
          'cutover_confirmation' => "cutover-whatsapp:#{key}:#{phone_number}"
        )
      }
    end
    {
      'TENANTS_JSON' => JSON.generate(TENANTS),
      'CHANNEL_READINESS_CONFIG_JSON' => JSON.generate(config),
      'GOOGLE_OAUTH_CONFIGURED' => 'true',
      'CHANNEL_READINESS_ENCRYPTION_CONFIGURED' => 'true',
      'CHANNEL_READINESS_IG_TOKEN' => 'true',
      'CHANNEL_READINESS_WA_TOKEN' => 'true',
      'CHANNEL_READINESS_WA_SECRET' => 'true',
      'HUBSPOT_CUTOVER_CONFIRMED' => 'true'
    }
  end

  def sensitive_values(env)
    JSON.parse(env.fetch('CHANNEL_READINESS_CONFIG_JSON')).flat_map do |config|
      [
        config.dig('email', 'mailbox'), config.dig('instagram', 'business_id'), config.dig('instagram', 'page_id'),
        config.dig('instagram', 'account_id'), config.dig('whatsapp', 'phone_number'), config.dig('whatsapp', 'waba_id'),
        config.dig('whatsapp', 'phone_number_id'), config.dig('whatsapp', 'hubspot_owner'),
        config.dig('whatsapp', 'hubspot_channel_account_id')
      ]
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/MethodLength
