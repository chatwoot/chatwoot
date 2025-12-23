# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module Ethon
        # Patcher enables patching of 'ethon' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'easy_patch'
            require_relative 'multi_patch'

            ::Ethon::Easy.include(EasyPatch)
            ::Ethon::Multi.include(MultiPatch)
          end
        end
      end
    end
  end
end
