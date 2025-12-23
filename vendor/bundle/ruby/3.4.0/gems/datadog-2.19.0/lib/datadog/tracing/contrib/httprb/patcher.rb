# frozen_string_literal: true

require_relative '../../../core/utils/only_once'
require_relative 'instrumentation'
require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      # Datadog Httprb integration.
      module Httprb
        # Patcher enables patching of 'httprb' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::HTTP::Client.include(Instrumentation)
          end
        end
      end
    end
  end
end
