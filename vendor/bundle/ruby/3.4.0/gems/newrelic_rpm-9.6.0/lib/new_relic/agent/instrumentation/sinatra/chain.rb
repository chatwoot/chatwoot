# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Sinatra
    module Chain
      def self.instrument!
        ::Sinatra::Base.class_eval do
          include ::NewRelic::Agent::Instrumentation::Sinatra::Tracer

          def dispatch_with_newrelic
            dispatch_with_tracing { dispatch_without_newrelic }
          end
          alias dispatch_without_newrelic dispatch!
          alias dispatch! dispatch_with_newrelic

          def process_route_with_newrelic(*args, &block)
            process_route_with_tracing(*args) do
              process_route_without_newrelic(*args, &block)
            end
          end
          alias process_route_without_newrelic process_route
          alias process_route process_route_with_newrelic

          def route_eval_with_newrelic(*args, &block)
            route_eval_with_tracing(*args) do
              route_eval_without_newrelic(*args, &block)
            end
          end
          alias route_eval_without_newrelic route_eval
          alias route_eval route_eval_with_newrelic
        end
      end
    end

    module Build
      module Chain
        def self.instrument!
          ::Sinatra::Base.class_eval do
            class << self
              def build_with_newrelic(*args, &block)
                build_with_tracing(*args) do
                  build_without_newrelic(*args, &block)
                end
              end
              alias build_without_newrelic build
              alias build build_with_newrelic
            end
          end
        end
      end
    end
  end
end
