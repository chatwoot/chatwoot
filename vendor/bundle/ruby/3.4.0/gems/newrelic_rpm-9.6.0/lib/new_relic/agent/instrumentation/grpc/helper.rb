# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module GRPC
        module Helper
          NR_8T_HOST_PATTERN = %r{tracing\.(?:staging-)?edge\.nr-data}.freeze

          def cleaned_method(method)
            method = method.to_s unless method.is_a?(String)
            return method unless method.start_with?('/')

            method[1..-1]
          end

          def host_denylisted?(host)
            return false unless host

            ignore_patterns.any? { |regex| host.match?(regex) }
          end

          def ignore_patterns
            ([NR_8T_HOST_PATTERN] + NewRelic::Agent.config[:'instrumentation.grpc.host_denylist']).freeze
          end
        end
      end
    end
  end
end
