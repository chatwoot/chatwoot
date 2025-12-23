# frozen_string_literal: true

module Datadog
  module Tracing
    module Distributed
      # Helper method to decide when to skip distributed tracing
      module PropagationPolicy
        module_function

        # Skips distributed tracing if disabled for this instrumentation
        # or if APM is disabled unless there is an AppSec event (from upstream distributed trace or local)
        #
        # Both pin_config and global_config are configuration for integrations.
        # pin_config is a Datadog::Core::Pin object, which gives the configuration of a single instance of an integration.
        # global_config is the config for all instances of an integration.
        def enabled?(pin_config: nil, global_config: nil, trace: nil)
          return false unless Tracing.enabled?

          unless ::Datadog.configuration.apm.tracing.enabled
            return false if trace.nil?

            trace_source = trace.get_tag(::Datadog::Tracing::Metadata::Ext::Distributed::TAG_TRACE_SOURCE)&.to_i(16)
            return false if trace_source.nil?

            # If AppSec is enabled and AppSec bit is set in the trace, we should not skip distributed tracing
            # Other products that will use dd.p.ts should implement similar behavior here
            if ::Datadog.configuration.appsec.enabled && (trace_source & ::Datadog::AppSec::Ext::PRODUCT_BIT) != 0
              return true
            end

            return false
          end

          return pin_config[:distributed_tracing] if pin_config && pin_config.key?(:distributed_tracing)
          return global_config[:distributed_tracing] if global_config

          true
        end
      end
    end
  end
end
