# frozen_string_literal: true

module Datadog
  module Core
    module Environment
      # Retrieves garbage collection statistics
      module GC
        module_function

        def stat
          ::GC.stat
        end

        def available?
          defined?(::GC) && ::GC.respond_to?(:stat)
        end
      end
    end
  end
end
