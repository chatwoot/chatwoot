# frozen_string_literal: true

require_relative '../../../core/utils/only_once'
require_relative '../patcher'
require_relative 'ext'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module Presto
        # Patcher enables patching of 'presto-client' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def patch
            ::Presto::Client::Client.include(Instrumentation::Client)
          end
        end
      end
    end
  end
end
