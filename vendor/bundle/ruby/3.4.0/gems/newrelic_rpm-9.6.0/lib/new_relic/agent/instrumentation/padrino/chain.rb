# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module PadrinoTracer
        module Chain
          def self.instrument!
            ::Padrino::Routing::InstanceMethods.module_eval do
              include NewRelic::Agent::Instrumentation::Sinatra

              def dispatch_with_newrelic
                dispatch_with_tracing { dispatch_without_newrelic }
              end

              alias dispatch_without_newrelic dispatch!
              alias dispatch! dispatch_with_newrelic

              # Padrino 0.13 mustermann routing
              if private_method_defined?(:invoke_route)
                include NewRelic::Agent::Instrumentation::Padrino

                def invoke_route_with_newrelic(*args, &block)
                  invoke_route_with_tracing(*args) { invoke_route_without_newrelic(*args, &block) }
                end

                alias invoke_route_without_newrelic invoke_route
                alias invoke_route invoke_route_with_newrelic
              end
            end
          end
        end
      end
    end
  end
end
