# frozen_string_literal: true

require_relative '../../../../core/utils'
require_relative '../../../metadata/ext'
require_relative '../ext'
require_relative 'event'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # DEV-3.0: Backwards compatibility code for the 2.x gem series.
          # DEV-3.0:
          # DEV-3.0: `ActiveSupport::Cache` is now instrumented by subscribing to ActiveSupport::Notifications events.
          # DEV-3.0: The implementation is located at {Datadog::Tracing::Contrib::ActiveSupport::Cache::Events::Cache}.
          # DEV-3.0: The events emitted provide richer introspection points (e.g. events for cache misses on `#fetch`) while
          # DEV-3.0: also ensuring we are using Rails' public API for improved compatibility.
          # DEV-3.0:
          # DEV-3.0: But a few operations holds us back:
          # DEV-3.0: 1. `ActiveSupport::Cache::Store#fetch`:
          # DEV-3.0:   This method does not have an event that can produce an equivalent span to today's 2.x implementation.
          # DEV-3.0:   In 2.x, `#fetch` produces two separate, *nested* spans: one for the `#read` operation and
          # DEV-3.0:   another for the `#write` operation that is called internally by `#fetch` when the cache key needs
          # DEV-3.0:   to be populated on a cache miss.
          # DEV-3.0:   But the ActiveSupport events emitted by `#fetch` provide two *sibling* events for the`#read` and
          # DEV-3.0:   `#write` operations.
          # DEV-3.0:   Moving from nested spans to sibling spans would be a breaking change. One notable difference is
          # DEV-3.0:   that if the nested `#write` operation fails 2.x, the `#read` span is marked as an error. This would
          # DEV-3.0:   not be the case with sibling spans, and would be a very visible change.
          # DEV-3.0: 2. `ActiveSupport::Cache::Store#read_multi` & `ActiveSupport::Cache::Store#fetch_multi`:
          # DEV-3.0:   ActiveSupport events were introduced in ActiveSupport 5.2.0 for these methods.
          # DEV-3.0:
          # DEV-3.0: At the end of the day, moving to ActiveSupport events is the better approach, but we have to retain
          # DEV-3.0: this last few monkey patches (and all the supporting code) to avoid a breaking change for now.
          #
          # Defines the deprecate  monkey-patch instrumentation for `ActiveSupport::Cache::Store#fetch`
          module Instrumentation
            module_function

            # @param action [String] type of cache operation. Will be set as the span resource.
            # @param key [Object] redis cache key. Used for actions with a single key locator.
            # @param multi_key [Array<Object>] list of redis cache keys. Used for actions with a multiple key locators.
            def trace(action, store, key: nil, multi_key: nil)
              return yield unless enabled?

              # create a new ``Span`` and add it to the tracing context
              Tracing.trace(
                Ext::SPAN_CACHE,
                type: Ext::SPAN_TYPE_CACHE,
                service: Datadog.configuration.tracing[:active_support][:cache_service],
                resource: action
              ) do |span|
                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_CACHE)

                if span.service != Datadog.configuration.service
                  span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
                end

                span.set_tag(Ext::TAG_CACHE_BACKEND, store) if store

                set_cache_key(span, key, multi_key) if Datadog.configuration.tracing[:active_support][:cache_key].enabled

                yield
              end
            end

            # In most of the cases, `#fetch()` and `#read()` calls are nested.
            # Instrument both does not add any value.
            # This method checks if these two operations are nested.
            #
            # DEV-3.0: We should not have these checks in the 3.x series because ActiveSupport events provide more
            # DEV-3.0: legible nested spans. While using ActiveSupport events, the nested spans actually provide meaningful
            # DEV-3.0: information.
            def nested_read?
              current_span = Tracing.active_span
              current_span && current_span.name == Ext::SPAN_CACHE && current_span.resource == Ext::RESOURCE_CACHE_GET
            end

            # (see #nested_read?)
            def nested_multiread?
              current_span = Tracing.active_span
              current_span && current_span.name == Ext::SPAN_CACHE && current_span.resource == Ext::RESOURCE_CACHE_MGET
            end

            def set_cache_key(span, single_key, multi_key)
              if multi_key
                resolved_key = multi_key.map { |key| ::ActiveSupport::Cache.expand_cache_key(key) }
                cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                span.set_tag(Ext::TAG_CACHE_KEY_MULTI, cache_key)
              else
                resolved_key = ::ActiveSupport::Cache.expand_cache_key(single_key)
                cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                span.set_tag(Ext::TAG_CACHE_KEY, cache_key)
              end
            end

            def enabled?
              Tracing.enabled? && Datadog.configuration.tracing[:active_support][:enabled]
            end

            # Instance methods injected into the cache client
            module InstanceMethods
              private

              # The name of the store is never saved.
              # ActiveSupport looks up stores by converting a symbol into a 'require' path,
              # then "camelizing" it for a `const_get` call:
              # ```
              # require "active_support/cache/#{store}"
              # ActiveSupport::Cache.const_get(store.to_s.camelize)
              # ```
              # @see https://github.com/rails/rails/blob/261975dbef77731d2c76f907f1076c5132ebc0e4/activesupport/lib/active_support/cache.rb#L139-L149
              #
              # As `self` is the store object, we can reverse engineer
              # the original symbol by converting the class name to snake case:
              # e.g. ActiveSupport::Cache::RedisStore -> active_support/cache/redis_store
              # In this case, `redis_store` is the store name.
              #
              # Because there's no API retrieve only the class name
              # (only `RedisStore`, and not `ActiveSupport::Cache::RedisStore`)
              # the easiest way to retrieve the store symbol is to convert the fully qualified
              # name using the Rails-provided method `#underscore`, which is the reverse of `#camelize`,
              # then extracting the last part of it.
              #
              # Also, this method caches the store name, given this value will be retrieve
              # multiple times and involves string manipulation.
              def dd_store_name
                return @store_name if defined?(@store_name)

                # DEV: String#underscore is available through ActiveSupport, and is
                # DEV: the exact reverse operation to `#camelize`.
                # DEV: String#demodulize is available through ActiveSupport, and is
                # DEV: used to remove the module ('*::') part of a constant name.
                @store_name = self.class.name.demodulize.underscore
              end
            end

            # Defines the the legacy monkey-patching instrumentation for ActiveSupport cache read_multi
            # DEV-3.0: ActiveSupport::Notifications events were introduced in ActiveSupport 5.2.0 for this method.
            # DEV-3.0: As long as we support ActiveSupport < 5.2.0, we have to keep this method.
            module ReadMulti
              include InstanceMethods

              def read_multi(*keys, **options, &block)
                return super if Instrumentation.nested_multiread?

                Instrumentation.trace(Ext::RESOURCE_CACHE_MGET, dd_store_name, multi_key: keys) { super }
              end
            end

            # Defines the the legacy monkey-patching instrumentation for ActiveSupport cache fetch
            module Fetch
              include InstanceMethods

              def fetch(*args, &block)
                return super if Instrumentation.nested_read?

                Instrumentation.trace(Ext::RESOURCE_CACHE_GET, dd_store_name, key: args[0]) { super }
              end
            end

            # Defines the the legacy monkey-patching instrumentation for ActiveSupport cache fetch_multi
            # DEV-3.0: ActiveSupport::Notifications events were introduced in ActiveSupport 5.2.0 for this method.
            # DEV-3.0: As long as we support ActiveSupport < 5.2.0, we have to keep this method.
            module FetchMulti
              include InstanceMethods

              def fetch_multi(*args, **options, &block)
                return super if Instrumentation.nested_multiread?

                keys = args[-1].instance_of?(Hash) ? args[0..-2] : args
                Instrumentation.trace(Ext::RESOURCE_CACHE_MGET, dd_store_name, multi_key: keys) { super }
              end
            end

            # Backports the payload[:store] key present since Rails 6.1:
            # https://github.com/rails/rails/commit/6fa747f2946ee244b2aab0cd8c3c064f05d950a5
            module Store
              def instrument(operation, key, options = nil)
                polyfill_options = options&.dup || {}
                polyfill_options[:store] = self.class.name
                super(operation, key, polyfill_options)
              end
            end

            # Save the original, user-supplied cache key, before it gets normalized.
            #
            # Normalized keys can include internal implementation detail,
            # for example FileStore keys include temp directory names, which
            # changes on every run, making it impossible to group by the cache key afterward.
            # Also, the user is never exposed to the normalized key, and only sets/gets using the
            # original key.
            module PreserveOriginalKey
              # Stores the original keys in the options hash, as an array of keys.
              # It's important to keep all the keys for multi-key operations.
              # For single-key operations, the key is stored as an array of a single element.
              def normalize_key(key, options)
                orig_keys = options[:dd_original_keys] || []
                orig_keys << key
                options[:dd_original_keys] = orig_keys

                super
              end

              # Ensure we don't pollute the default Store instance `options` in {PreserveOriginalKey#normalize_key}.
              # In most cases, `merged_options` returns a new hash,
              # but we check for cases where it reuses the instance hash.
              def merged_options(call_options)
                ret = super

                if ret.equal?(options)
                  ret.dup
                else
                  ret
                end
              end
            end
          end
        end
      end
    end
  end
end
