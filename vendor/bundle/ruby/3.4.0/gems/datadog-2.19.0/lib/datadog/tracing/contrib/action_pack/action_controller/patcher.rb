# frozen_string_literal: true

require_relative '../../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        module ActionController
          # Patcher for ActionController components
          module Patcher
            include Contrib::Patcher

            module_function

            def target_version
              Integration.version
            end

            def patch
              ::ActionController::Metal.prepend(ActionController::Instrumentation::Metal)
            end
          end
        end
      end
    end
  end
end
