# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'events'
require_relative 'log_injection'

module Datadog
  module Tracing
    module Contrib
      module ActiveJob
        # Patcher enables patching of 'active_job' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            Events.subscribe!
            inject_log_correlation
          end

          def inject_log_correlation
            ::ActiveSupport.on_load(:active_job) do
              include LogInjection
            end
          end
        end
      end
    end
  end
end
