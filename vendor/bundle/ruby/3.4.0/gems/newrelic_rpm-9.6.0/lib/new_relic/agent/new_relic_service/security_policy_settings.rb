# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class NewRelicService
      module SecurityPolicySettings
        EXPECTED_SECURITY_POLICIES = %w[
          record_sql
          attributes_include
          allow_raw_exception_messages
          custom_events
          custom_parameters
          custom_instrumentation_editor
          message_parameters
        ].map(&:freeze)

        def self.preliminary_settings(security_policies)
          enabled_key = 'enabled'.freeze
          settings = EXPECTED_SECURITY_POLICIES.inject({}) do |memo, policy_name|
            memo[policy_name] = {enabled_key => security_policies[policy_name][enabled_key]}
            memo
          end
          {'security_policies' => settings}
        end

        class Validator
          def initialize(preconnect_response)
            @preconnect_policies = preconnect_response['security_policies'] || {}
          end

          def validate_matching_agent_config!
            agent_keys = EXPECTED_SECURITY_POLICIES
            all_server_keys = @preconnect_policies.keys
            required = 'required'
            required_server_keys = @preconnect_policies.keys.select do |key|
              key if @preconnect_policies[key][required]
            end

            missing_from_agent = required_server_keys - agent_keys
            unless missing_from_agent.empty?
              message = "The agent received one or more required security policies \
that it does not recognize and will shut down: #{missing_from_agent.join(',')}. \
Please check if a newer agent version supports these policies or contact support."
              raise NewRelic::Agent::UnrecoverableAgentException.new(message)
            end

            missing_from_server = agent_keys - all_server_keys
            unless missing_from_server.empty?
              message = "The agent did not receive one or more security policies \
that it expected and will shut down: #{missing_from_server.join(',')}. Please \
contact support."
              raise NewRelic::Agent::UnrecoverableAgentException.new(message)
            end
          end
        end
      end
    end
  end
end
