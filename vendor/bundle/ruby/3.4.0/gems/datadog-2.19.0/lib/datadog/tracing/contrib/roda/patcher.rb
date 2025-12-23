# frozen_string_literal: true

# typed: ignore

require_relative '../patcher'
require_relative 'ext'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module Roda
        # Patcher enables patching of 'roda'
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Roda.prepend(Instrumentation)
          end
        end
      end
    end
  end
end
