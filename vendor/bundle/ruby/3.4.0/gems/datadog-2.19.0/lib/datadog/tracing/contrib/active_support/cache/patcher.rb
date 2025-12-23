# frozen_string_literal: true

require_relative '../../patcher'
require_relative 'instrumentation'
require_relative 'events'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Patcher enables patching of 'active_support' module.
          module Patcher
            include Contrib::Patcher

            module_function

            def target_version
              Integration.version
            end

            def patch
              Events.subscribe!

              if Integration.version >= Gem::Version.new('8.0.0')
                ::ActiveSupport::Cache::Store.prepend(Cache::Instrumentation::PreserveOriginalKey)
              end

              # Backfill the `:store` key in the ActiveSupport event payload for older Rails.
              if Integration.version < Gem::Version.new('6.1.0')
                ::ActiveSupport::Cache::Store.prepend(Cache::Instrumentation::Store)
              end

              # DEV-3.0: Backwards compatibility code for the 2.x gem series.
              # DEV-3.0: See documentation at {Datadog::Tracing::Contrib::ActiveSupport::Cache::Instrumentation}
              # DEV-3.0: for the complete information about this backwards compatibility code.
              patch_legacy_cache_store
            end

            # This method is overwritten by
            # `datadog/tracing/contrib/active_support/cache/redis.rb`
            # with more complex behavior.
            def cache_store_class(meth)
              [::ActiveSupport::Cache::Store]
            end

            def patch_legacy_cache_store
              cache_store_class(:read_multi).each { |clazz| clazz.prepend(Cache::Instrumentation::ReadMulti) }
              cache_store_class(:fetch).each { |clazz| clazz.prepend(Cache::Instrumentation::Fetch) }
              cache_store_class(:fetch_multi).each { |clazz| clazz.prepend(Cache::Instrumentation::FetchMulti) }
            end
          end
        end
      end
    end
  end
end
