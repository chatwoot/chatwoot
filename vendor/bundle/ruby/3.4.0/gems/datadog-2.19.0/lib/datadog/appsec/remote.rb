# frozen_string_literal: true

require_relative '../core/remote/dispatcher'
require_relative 'processor/rule_loader'

module Datadog
  module AppSec
    # Remote
    module Remote
      class ReadError < StandardError; end

      class NoRulesError < StandardError; end

      class << self
        CAP_ASM_RESERVED_1 = 1 << 0   # RESERVED
        CAP_ASM_ACTIVATION = 1 << 1   # Remote activation via ASM_FEATURES product
        CAP_ASM_IP_BLOCKING = 1 << 2   # accept IP blocking data from ASM_DATA product
        CAP_ASM_DD_RULES = 1 << 3   # read ASM rules from ASM_DD product
        CAP_ASM_EXCLUSIONS = 1 << 4   # exclusion filters (passlist) via ASM product
        CAP_ASM_REQUEST_BLOCKING = 1 << 5   # can block on request info
        CAP_ASM_RESPONSE_BLOCKING = 1 << 6   # can block on response info
        CAP_ASM_USER_BLOCKING = 1 << 7   # accept user blocking data from ASM_DATA product
        CAP_ASM_CUSTOM_RULES = 1 << 8   # accept custom rules
        CAP_ASM_CUSTOM_BLOCKING_RESPONSE = 1 << 9   # supports custom http code or redirect sa blocking response
        CAP_ASM_TRUSTED_IPS = 1 << 10  # supports trusted ip
        CAP_ASM_RASP_SSRF = 1 << 23  # support for server-side request forgery exploit prevention rules
        CAP_ASM_RASP_SQLI = 1 << 21  # support for SQL injection exploit prevention rules

        # TODO: we need to dynamically add CAP_ASM_ACTIVATION once we support it
        ASM_CAPABILITIES = [
          CAP_ASM_IP_BLOCKING,
          CAP_ASM_USER_BLOCKING,
          CAP_ASM_EXCLUSIONS,
          CAP_ASM_REQUEST_BLOCKING,
          CAP_ASM_RESPONSE_BLOCKING,
          CAP_ASM_DD_RULES,
          CAP_ASM_CUSTOM_RULES,
          CAP_ASM_CUSTOM_BLOCKING_RESPONSE,
          CAP_ASM_TRUSTED_IPS,
          CAP_ASM_RASP_SSRF,
          CAP_ASM_RASP_SQLI,
        ].freeze

        ASM_PRODUCTS = [
          'ASM_DD',       # Datadog employee issued configuration
          'ASM',          # customer issued configuration (rulesets, passlist...)
          'ASM_FEATURES', # capabilities
          'ASM_DATA',     # config files (IP addresses or users for blocking)
        ].freeze

        def capabilities
          remote_features_enabled? ? ASM_CAPABILITIES : []
        end

        def products
          remote_features_enabled? ? ASM_PRODUCTS : []
        end

        def receivers(telemetry)
          return [] unless remote_features_enabled?

          matcher = Core::Remote::Dispatcher::Matcher::Product.new(ASM_PRODUCTS)
          receiver = Core::Remote::Dispatcher::Receiver.new(matcher) do |repository, changes|
            next unless AppSec.security_engine

            changes.each do |change|
              content = repository[change.path]
              next unless content || change.type == :delete

              case change.type
              when :insert, :update
                AppSec.security_engine.add_or_update_config(parse_content(content), path: change.path.to_s) # steep:ignore

                content.applied # steep:ignore
              when :delete
                AppSec.security_engine.remove_config_at_path(change.path.to_s) # steep:ignore
              end
            end

            # This is subject to change - we need to remove the reconfiguration mutex
            # and track usages of each WAF handle instead, so that we know when an old
            # WAF handle can be finalized.
            AppSec.reconfigure!
          end

          [receiver]
        end

        private

        def remote_features_enabled?
          Datadog.configuration.appsec.using_default?(:ruleset)
        end

        def parse_content(content)
          data = content.data.read

          content.data.rewind

          raise ReadError, 'EOF reached' if data.nil?

          JSON.parse(data)
        end
      end
    end
  end
end
