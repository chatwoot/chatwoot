# frozen_string_literal: true

require_relative '../patcher'
require_relative 'tracer'

module Datadog
  module Tracing
    module Contrib
      module Sneakers
        # Patcher enables patching of 'sneakers' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Sneakers.middleware.use(Sneakers::Tracer, nil)
          end
        end
      end
    end
  end
end
