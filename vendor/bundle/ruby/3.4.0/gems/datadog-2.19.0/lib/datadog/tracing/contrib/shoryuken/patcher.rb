# frozen_string_literal: true

require_relative 'tracer'

module Datadog
  module Tracing
    module Contrib
      module Shoryuken
        # Patcher enables patching of 'shoryuken' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Shoryuken.server_middleware do |chain|
              chain.add Shoryuken::Tracer
            end
          end
        end
      end
    end
  end
end
