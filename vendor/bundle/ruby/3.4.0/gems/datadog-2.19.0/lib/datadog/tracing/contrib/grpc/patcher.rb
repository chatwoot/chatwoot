# frozen_string_literal: true

require_relative 'ext'
require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        # Patcher enables patching of 'grpc' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'intercept_with_datadog'

            prepend_interceptor
          end

          def prepend_interceptor
            ::GRPC::InterceptionContext
              .prepend(InterceptWithDatadog)
          end
        end
      end
    end
  end
end
