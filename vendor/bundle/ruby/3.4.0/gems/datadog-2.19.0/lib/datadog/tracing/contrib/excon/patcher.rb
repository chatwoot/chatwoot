# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module Excon
        # Patcher enables patching of 'excon' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'middleware'
            add_middleware
          end

          def add_middleware
            ::Excon.defaults[:middlewares] = Middleware.around_default_stack
          end
        end
      end
    end
  end
end
