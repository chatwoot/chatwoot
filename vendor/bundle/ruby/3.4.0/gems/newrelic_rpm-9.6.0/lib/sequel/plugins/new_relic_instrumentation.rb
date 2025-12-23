# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'sequel' unless defined?(Sequel)
require 'newrelic_rpm' unless defined?(NewRelic)
require 'new_relic/agent/instrumentation/sequel_helper'
require 'new_relic/agent/datastores/metric_helper'

module Sequel
  module Plugins
    # Sequel::Model instrumentation for the New Relic agent.
    module NewRelicInstrumentation
      # Meta-programming for creating method tracers for the Sequel::Model plugin.
      module MethodWrapping
        # Install a method named +method_name+ that will trace execution
        # with a metric name derived from +operation_name+ (or +method_name+ if +operation_name+
        # isn't specified).
        def wrap_sequel_method(method_name, operation_name = method_name)
          define_method(method_name) do |*args, &block|
            klass = self.is_a?(Class) ? self : self.class
            product = NewRelic::Agent::Instrumentation::SequelHelper.product_name_from_adapter(db.adapter_scheme)
            segment = NewRelic::Agent::Tracer.start_datastore_segment(
              product: product,
              operation: operation_name,
              collection: klass.name
            )

            begin
              NewRelic::Agent.disable_all_tracing { super(*args, &block) }
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end
          end
        end
      end # module MethodTracer

      # Methods to be added to Sequel::Model instances.
      module InstanceMethods
        extend Sequel::Plugins::NewRelicInstrumentation::MethodWrapping

        wrap_sequel_method :delete
        wrap_sequel_method :destroy
        wrap_sequel_method :update
        wrap_sequel_method :update_all
        wrap_sequel_method :update_except
        wrap_sequel_method :update_fields
        wrap_sequel_method :update_only
        wrap_sequel_method :save
      end # module InstanceMethods

      # Methods to be added to Sequel::Model classes.
      module ClassMethods
        extend Sequel::Plugins::NewRelicInstrumentation::MethodWrapping

        wrap_sequel_method :[], 'get'
        wrap_sequel_method :all
        wrap_sequel_method :first
        wrap_sequel_method :create
      end # module ClassMethods
    end # module NewRelicInstrumentation
  end # module Plugins
end # module Sequel
