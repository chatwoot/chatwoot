# frozen_string_literal: true

require_relative '../patcher'
require_relative 'cache/patcher'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        # Patcher enables patching of 'active_support' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            Cache::Patcher.patch
          end
        end
      end
    end
  end
end
