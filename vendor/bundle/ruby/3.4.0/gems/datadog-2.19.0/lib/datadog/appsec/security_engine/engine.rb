# frozen_string_literal: true

module Datadog
  module AppSec
    module SecurityEngine
      # SecurityEngine::Engine creates WAF builder and manages its configuration.
      # It also rebuilds WAF handle from the WAF builder when configuration changes.
      class Engine
        DEFAULT_RULES_CONFIG_PATH = 'ASM_DD/default'
        TELEMETRY_ACTIONS = %w[init update].freeze
        DIAGNOSTICS_CONFIG_KEYS = %w[
          rules
          custom_rules
          exclusions
          actions
          processors
          scanners
          rules_override
          rules_data
          exclusion_data
        ].freeze

        attr_reader :waf_addresses, :ruleset_version

        def initialize(appsec_settings:, telemetry:)
          @default_ruleset = appsec_settings.ruleset

          # NOTE: replace appsec_settings argument with default_ruleset when removing these deprecated settings
          @default_ip_denylist = appsec_settings.ip_denylist
          @default_user_id_denylist = appsec_settings.user_id_denylist
          @default_ip_passlist = appsec_settings.ip_passlist

          @waf_builder = WAF::HandleBuilder.new(
            obfuscator: {
              key_regex: appsec_settings.obfuscator_key_regex,
              value_regex: appsec_settings.obfuscator_value_regex
            }
          )

          diagnostics = load_default_config(telemetry: telemetry)
          report_configuration_diagnostics(diagnostics, action: 'init', telemetry: telemetry)

          @waf_handle = @waf_builder.build_handle
          @waf_addresses = @waf_handle.known_addresses
        rescue WAF::Error => e
          error_message = "AppSec security engine failed to initialize"

          Datadog.logger.error("#{error_message}, error #{e.inspect}")
          telemetry.report(e, description: error_message)

          raise e
        end

        def finalize!
          @waf_handle&.finalize!
          @waf_builder&.finalize!

          @waf_addresses = []
          @ruleset_version = nil
        end

        def new_runner
          SecurityEngine::Runner.new(@waf_handle.build_context)
        end

        def add_or_update_config(config, path:)
          @is_ruleset_update = path.include?('ASM_DD')

          # default config has to be removed when adding an ASM_DD config
          remove_config_at_path(DEFAULT_RULES_CONFIG_PATH) if @is_ruleset_update

          diagnostics = @waf_builder.add_or_update_config(config, path: path)
          @ruleset_version = diagnostics['ruleset_version'] if diagnostics.key?('ruleset_version')
          report_configuration_diagnostics(diagnostics, action: 'update', telemetry: AppSec.telemetry)

          # we need to load default config if diagnostics contains top-level error for rules or processors
          if @is_ruleset_update &&
              (diagnostics.key?('error') ||
              diagnostics.dig('rules', 'error') ||
              diagnostics.dig('processors', 'errors'))
            diagnostics = load_default_config(telemetry: AppSec.telemetry)
            report_configuration_diagnostics(diagnostics, action: 'update', telemetry: AppSec.telemetry)
          end

          diagnostics
        rescue WAF::Error => e
          error_message = "libddwaf builder failed to add or update config at path: #{path}"

          Datadog.logger.debug("#{error_message}, error: #{e.inspect}")
          AppSec.telemetry.report(e, description: error_message)
        end

        def remove_config_at_path(path)
          result = @waf_builder.remove_config_at_path(path)

          if result && path != DEFAULT_RULES_CONFIG_PATH && path.include?('ASM_DD')
            diagnostics = load_default_config(telemetry: AppSec.telemetry)
            report_configuration_diagnostics(diagnostics, action: 'update', telemetry: AppSec.telemetry)
          end

          result
        rescue WAF::Error => e
          error_message = "libddwaf handle builder failed to remove config at path: #{path}"

          Datadog.logger.error("#{error_message}, error: #{e.inspect}")
          AppSec.telemetry.report(e, description: error_message)
        end

        def reconfigure!
          old_waf_handle = @waf_handle

          @waf_handle = @waf_builder.build_handle
          @waf_addresses = @waf_handle.known_addresses

          old_waf_handle&.finalize!
        rescue WAF::Error => e
          error_message = "AppSec security engine failed to reconfigure"

          Datadog.logger.error("#{error_message}, error #{e.inspect}")
          AppSec.telemetry.report(e, description: error_message)

          if old_waf_handle
            Datadog.logger.warn("Reverting to the previous configuration")

            @waf_handle = old_waf_handle
            @waf_addresses = old_waf_handle.known_addresses
          end
        end

        private

        def load_default_config(telemetry:)
          config = AppSec::Processor::RuleLoader.load_rules(telemetry: telemetry, ruleset: @default_ruleset)

          # deprecated - ip and user id denylists should be configured via RC
          config['rules_data'] ||= AppSec::Processor::RuleLoader.load_data(
            ip_denylist: @default_ip_denylist,
            user_id_denylist: @default_user_id_denylist
          )

          # deprecated - ip passlist should be configured via RC
          config['exclusions'] ||= AppSec::Processor::RuleLoader.load_exclusions(ip_passlist: @default_ip_passlist)

          diagnostics = @waf_builder.add_or_update_config(config, path: DEFAULT_RULES_CONFIG_PATH)
          @ruleset_version = diagnostics['ruleset_version']

          diagnostics
        end

        def report_configuration_diagnostics(diagnostics, action:, telemetry:)
          raise ArgumentError, 'action must be one of TELEMETRY_ACTIONS' unless TELEMETRY_ACTIONS.include?(action)

          common_tags = {
            waf_version: Datadog::AppSec::WAF::VERSION::BASE_STRING,
            event_rules_version: diagnostics.fetch('ruleset_version', @ruleset_version).to_s,
            action: action
          }

          if diagnostics['error']
            telemetry.inc(
              Ext::TELEMETRY_METRICS_NAMESPACE, 'waf.config_errors', 1,
              tags: common_tags.merge(scope: 'top-level')
            )

            telemetry.error(diagnostics['error'])
          end

          diagnostics.each do |config_key, config_diagnostics|
            next unless DIAGNOSTICS_CONFIG_KEYS.include?(config_key)
            next if !config_diagnostics.key?('error') && config_diagnostics.fetch('errors', []).empty?

            if config_diagnostics['error']
              telemetry.error(config_diagnostics['error'])

              telemetry.inc(
                Ext::TELEMETRY_METRICS_NAMESPACE, 'waf.config_errors', 1,
                tags: common_tags.merge(config_key: config_key, scope: 'top-level')
              )
            elsif config_diagnostics['errors']
              config_diagnostics['errors'].each do |error, config_ids|
                telemetry.error("#{error}: [#{config_ids.join(",")}]")
              end

              telemetry.inc(
                Ext::TELEMETRY_METRICS_NAMESPACE, 'waf.config_errors', config_diagnostics['errors'].count,
                tags: common_tags.merge(config_key: config_key, scope: 'item')
              )
            end
          end
        end
      end
    end
  end
end
