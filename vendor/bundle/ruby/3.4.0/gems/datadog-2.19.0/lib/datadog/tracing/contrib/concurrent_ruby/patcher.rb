# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # Patcher enables patching of 'Future' and 'Async' classes.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'future_patch'
            patch_future
            require_relative 'promises_future_patch'
            patch_promises_future
            require_relative 'async_patch'
            async_patch
          end

          # Propagate tracing context in Concurrent::Async
          def async_patch
            if defined?(::Concurrent::Async)
              # NOTE: AsyncDelegator is a private constant
              ::Concurrent::Async.const_get(:AsyncDelegator).prepend(AsyncPatch)
            end
          end

          # Propagate tracing context in Concurrent::Future
          def patch_future
            ::Concurrent::Future.prepend(FuturePatch) if defined?(::Concurrent::Future)
          end

          # Propagate tracing context in Concurrent::Promises::Future
          def patch_promises_future
            ::Concurrent::Promises.singleton_class.prepend(PromisesFuturePatch) if defined?(::Concurrent::Promises::Future)
          end
        end
      end
    end
  end
end
