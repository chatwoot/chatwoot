# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Roda
    module Chain
      def self.instrument!
        ::Roda.class_eval do
          include ::NewRelic::Agent::Instrumentation::Roda::Tracer

          alias_method(:_roda_handle_main_route_without_tracing, :_roda_handle_main_route)

          def _roda_handle_main_route(*args)
            _roda_handle_main_route_with_tracing(*args) do
              _roda_handle_main_route_without_tracing(*args)
            end
          end
        end
      end
    end

    module Build
      module Chain
        def self.instrument!
          ::Roda.class_eval do
            include ::NewRelic::Agent::Instrumentation::Roda::Tracer

            class << self
              alias_method(:build_rack_app_without_tracing, :build_rack_app)

              def build_rack_app
                build_rack_app_with_tracing do
                  build_rack_app_without_tracing
                end
              end
            end
          end
        end
      end
    end
  end
end
