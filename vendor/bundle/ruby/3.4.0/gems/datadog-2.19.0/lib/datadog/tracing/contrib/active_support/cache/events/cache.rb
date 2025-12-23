# frozen_string_literal: true

require_relative '../../ext'
require_relative '../event'
require_relative '../../../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          module Events
            # Defines instrumentation for instantiation.active_record event
            module Cache
              include ActiveSupport::Cache::Event

              module_function

              # Acts as this module's initializer.
              def subscribe!
                @cache_backend = {}
                super
              end

              def event_name
                /\Acache_(?:delete|read|read_multi|write|write_multi)\.active_support\z/
              end

              def span_name
                Ext::SPAN_CACHE
              end

              def span_options
                {
                  type: Ext::SPAN_TYPE_CACHE
                }
              end

              # DEV: Look for other uses of `ActiveSupport::Cache::Store#instrument`, to find other useful event keys.
              MAPPING = {
                'cache_delete.active_support' => { resource: Ext::RESOURCE_CACHE_DELETE },
                'cache_read.active_support' => { resource: Ext::RESOURCE_CACHE_GET },
                'cache_read_multi.active_support' => { resource: Ext::RESOURCE_CACHE_MGET, multi_key: true },
                'cache_write.active_support' => { resource: Ext::RESOURCE_CACHE_SET },
                'cache_write_multi.active_support' => { resource: Ext::RESOURCE_CACHE_MSET, multi_key: true }
              }.freeze

              def trace?(event, payload)
                return false if !Tracing.enabled? || !configuration.enabled

                if (cache_store = configuration[:cache_store])
                  store = cache_backend(payload[:store])

                  return false unless cache_store.include?(store)
                end

                # DEV-3.0: Backwards compatibility code for the 2.x gem series.
                # DEV-3.0: See documentation at {Datadog::Tracing::Contrib::ActiveSupport::Cache::Instrumentation}
                # DEV-3.0: for the complete information about this backwards compatibility code.
                case event
                when 'cache_read.active_support'
                  !ActiveSupport::Cache::Instrumentation.nested_read?
                when 'cache_read_multi.active_support'
                  !ActiveSupport::Cache::Instrumentation.nested_multiread?
                else
                  true
                end
              end

              def on_start(span, event, _id, payload)
                # Since Rails 8, `dd_original_keys` contains the denormalized key provided by the user.
                # In previous versions, the denormalized key is stored in the official `key` attribute.
                # We fall back to `key`, even in Rails 8, as a defensive measure.
                key = payload[:dd_original_keys] || payload[:key]
                store = payload[:store]

                mapping = MAPPING.fetch(event)

                span.service = configuration[:cache_service]
                span.resource = mapping[:resource]

                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_CACHE)

                if span.service != Datadog.configuration.service
                  span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
                end

                span.set_tag(Ext::TAG_CACHE_BACKEND, cache_backend(store))

                span.set_tag('EVENT', event)

                if Datadog.configuration.tracing[:active_support][:cache_key].enabled
                  set_cache_key(span, key, mapping[:multi_key])
                end
              rescue StandardError => e
                Datadog.logger.error(e.message)
                Datadog::Core::Telemetry::Logger.report(e)
              end

              def set_cache_key(span, key, multi_key)
                if multi_key
                  keys = key.is_a?(Hash) ? key.keys : key # `write`s use Hashes, while `read`s use Arrays
                  resolved_key = keys.map { |k| ::ActiveSupport::Cache.expand_cache_key(k) }
                  cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                  span.set_tag(Ext::TAG_CACHE_KEY_MULTI, cache_key)
                else
                  resolved_key = ::ActiveSupport::Cache.expand_cache_key(key)
                  cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                  span.set_tag(Ext::TAG_CACHE_KEY, cache_key)
                end
              end

              # The name of the `store` is never saved by Rails.
              # ActiveSupport looks up stores by converting a symbol into a 'require' path,
              # then "camelizing" it for a `const_get` call:
              # ```
              # require "active_support/cache/#{store}"
              # ActiveSupport::Cache.const_get(store.to_s.camelize)
              # ```
              # @see https://github.com/rails/rails/blob/261975dbef77731d2c76f907f1076c5132ebc0e4/activesupport/lib/active_support/cache.rb#L139-L149
              #
              # We can reverse engineer
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
              def cache_backend(store)
                # Cache the backend name to avoid the expensive string manipulation required to calculate it.
                # DEV: We can't store it directly in the `store` object because it is a frozen String.
                if (name = @cache_backend[store])
                  return name
                end

                # DEV: #underscore is available through ActiveSupport, and is
                # DEV: the exact reverse operation to `#camelize`.
                # DEV: #demodulize is available through ActiveSupport, and is
                # DEV: used to remove the module ('*::') part of a constant name.
                name = ::ActiveSupport::Inflector.demodulize(store)
                name = ::ActiveSupport::Inflector.underscore(name)

                # Despite a given application only ever having 1-3 store types,
                # we limit the size of the `@cache_backend` just in case, because
                # the user can create custom Cache store classes themselves.
                @cache_backend[store] = name if @cache_backend.size < 50

                name
              end

              # DEV: There are two possibly interesting fields in the `on_finish` payload:
              # | `:hit`             | If this read is a hit   |
              # | `:super_operation` | `:fetch` if a read is done with [`fetch`][ActiveSupport::Cache::Store#fetch] |
              # @see https://github.com/rails/rails/blob/b9d6759401c3d50a51e0a7650cb2331f4218d11f/guides/source/active_support_instrumentation.md?plain=1#L528-L529
              # def on_finish(span, event, id, payload)
              #   super
              # end
            end
          end
        end
      end
    end
  end
end
