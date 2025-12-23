# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/configuration/dotted_hash'

module NewRelic
  module Agent
    module Configuration
      class HighSecuritySource < DottedHash
        def initialize(local_settings)
          super({
            :capture_params => false,
            :'attributes.include' => [],

            :'transaction_tracer.record_sql' => record_sql_setting(local_settings, :'transaction_tracer.record_sql'),
            :'slow_sql.record_sql' => record_sql_setting(local_settings, :'slow_sql.record_sql'),
            :'mongo.obfuscate_queries' => true,
            :'elasticsearch.obfuscate_queries' => true,
            :'transaction_tracer.record_redis_arguments' => false,

            :'custom_insights_events.enabled' => false,
            :'strip_exception_messages.enabled' => true
          })
        end

        OFF = 'off'.freeze
        RAW = 'raw'.freeze
        OBFUSCATED = 'obfuscated'.freeze

        SET_TO_OBFUSCATED = [RAW, OBFUSCATED]

        def record_sql_setting(local_settings, key)
          original_value = local_settings[key]
          result = if SET_TO_OBFUSCATED.include?(original_value)
            OBFUSCATED
          else
            OFF
          end

          if result != original_value
            NewRelic::Agent.logger.info("Disabling setting #{key}='#{original_value}' because high security mode is enabled. Value will be '#{result}'")
          end

          result
        end
      end
    end
  end
end
