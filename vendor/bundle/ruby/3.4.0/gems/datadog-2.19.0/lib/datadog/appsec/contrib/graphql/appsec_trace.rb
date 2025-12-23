# frozen_string_literal: true

require 'json'
require_relative 'gateway/multiplex'
require_relative '../../instrumentation/gateway'

module Datadog
  module AppSec
    module Contrib
      module GraphQL
        # These methods will be called by the GraphQL runtime to send the variables to the WAF.
        # We actually don't need to create any span/trace.
        module AppSecTrace
          def execute_multiplex(multiplex:)
            return super unless Datadog::AppSec.enabled?

            gateway_multiplex = Gateway::Multiplex.new(multiplex)

            multiplex_return, _gateway_multiplex = Instrumentation.gateway.push('graphql.multiplex', gateway_multiplex) do
              super
            end

            multiplex_return
          end
        end
      end
    end
  end
end
