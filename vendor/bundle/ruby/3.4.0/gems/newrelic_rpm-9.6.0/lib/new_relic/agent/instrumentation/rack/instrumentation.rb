# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module RackBuilder
        INSTRUMENTATION_NAME = 'Rack'

        def self.track_deferred_detection(builder_class)
          class << builder_class
            attr_accessor :_nr_deferred_detection_ran
          end
          builder_class._nr_deferred_detection_ran = false
        end

        def deferred_dependency_check
          return if self.class._nr_deferred_detection_ran

          NewRelic::Agent.logger.info('Doing deferred dependency-detection before Rack startup')
          DependencyDetection.detect!
          self.class._nr_deferred_detection_ran = true
        end

        def check_for_late_instrumentation(app)
          return if defined?(@checked_for_late_instrumentation) && @checked_for_late_instrumentation

          @checked_for_late_instrumentation = true
          if middleware_instrumentation_enabled?
            if ::NewRelic::Agent::Instrumentation::MiddlewareProxy.needs_wrapping?(app)
              ::NewRelic::Agent.logger.info("We weren't able to instrument all of your Rack middlewares.",
                "To correct this, ensure you 'require \"newrelic_rpm\"' before setting up your middleware stack.")
            end
          end
        end

        # We patch the #to_app method for a reason that actually has nothing to do with
        # instrumenting rack itself. It happens to be a convenient and
        # easy-to-hook point that happens late in the startup sequence of almost
        # every application, making it a good place to do a final call to
        # DependencyDetection.detect!, since all libraries are likely loaded at
        # this point.
        def with_deferred_dependency_detection
          deferred_dependency_check
          yield.tap { |result| check_for_late_instrumentation(result) }
        end

        def middleware_instrumentation_enabled?
          ::NewRelic::Agent::Instrumentation::RackHelpers.middleware_instrumentation_enabled?
        end

        def run_with_tracing(app)
          return yield(app) unless middleware_instrumentation_enabled?

          NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

          yield(::NewRelic::Agent::Instrumentation::MiddlewareProxy.wrap(app, true))
        end

        def use_with_tracing(middleware_class)
          return if middleware_class.nil?
          return yield(middleware_class) unless middleware_instrumentation_enabled?

          NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

          yield(::NewRelic::Agent::Instrumentation::MiddlewareProxy.for_class(middleware_class))
        end
      end

      module RackURLMap
        def self.generate_traced_map(map)
          map.inject({}) do |traced_map, (url, handler)|
            traced_map[url] = NewRelic::Agent::Instrumentation::MiddlewareProxy.wrap(handler, true)
            traced_map
          end
        end
      end
    end
  end
end
