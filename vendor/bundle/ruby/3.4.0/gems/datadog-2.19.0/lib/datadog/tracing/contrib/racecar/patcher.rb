# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'events'

module Datadog
  module Tracing
    module Contrib
      module Racecar
        # Patcher enables patching of 'racecar' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            # Subscribe to Racecar events
            Events.subscribe!
          end
        end
      end
    end
  end
end
