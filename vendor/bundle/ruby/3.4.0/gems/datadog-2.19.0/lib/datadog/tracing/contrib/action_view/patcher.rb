# frozen_string_literal: true

require_relative '../../../core'
require_relative '../patcher'
require_relative 'events'
require_relative 'ext'
require_relative 'utils'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        # Patcher enables patching of ActionView module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            patch_renderer
          end

          def patch_renderer
            Events.subscribe!
          end
        end
      end
    end
  end
end
