# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module DelayedJob
        # Patcher enables patching of 'delayed_job' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'plugin'
            add_instrumentation(::Delayed::Worker)
            patch_server_internals
          end

          def add_instrumentation(klass)
            klass.plugins << Plugin
          end

          def patch_server_internals
            require_relative 'server_internal_tracer/worker'
            ::Delayed::Worker.prepend(ServerInternalTracer::Worker)
          end
        end
      end
    end
  end
end
