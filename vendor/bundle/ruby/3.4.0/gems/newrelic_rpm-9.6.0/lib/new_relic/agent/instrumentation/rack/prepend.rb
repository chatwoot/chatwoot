# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Rack
    module URLMap
      module Prepend
        def initialize(map = {})
          super(::NewRelic::Agent::Instrumentation::RackURLMap.generate_traced_map(map))
        end
      end
    end

    module Prepend
      include ::NewRelic::Agent::Instrumentation::RackBuilder

      def self.prepended(builder_class)
        NewRelic::Agent::Instrumentation::RackBuilder.track_deferred_detection(builder_class)
      end

      def to_app
        with_deferred_dependency_detection { super }
      end

      def run(app = nil, *args, &block)
        app_or_block = app || block
        run_with_tracing(app_or_block) do |wrapped|
          # Rack::Builder#run for Rack v3+ supports a block, and does not
          # support args. Whether a block or an app is provided, that callable
          # object will be wrapped into a MiddlewareProxy instance. That
          # proxy instance must then be passed to super as the app argument.
          block ? super(wrapped, &nil) : super(wrapped, *args)
        end
      end

      def use(middleware_class, *args, &blk)
        use_with_tracing(middleware_class) { |wrapped_class| super(wrapped_class, *args, &blk) }
      end
      ruby2_keywords(:use) if respond_to?(:ruby2_keywords, true)
    end
  end
end
