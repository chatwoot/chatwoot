# frozen_string_literal: true

require_relative '../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module Trilogy
        # Patcher enables patching of 'trilogy' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            patch_trilogy_client
          end

          def patch_trilogy_client
            ::Trilogy.include(Instrumentation)
          end
        end
      end
    end
  end
end
