# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Configuration
          # Custom settings for the ActiveSupport integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            # @!visibility private
            option :analytics_enabled do |o|
              o.type :bool
              o.env Ext::ENV_ANALYTICS_ENABLED
              o.default false
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :cache_service do |o|
              o.type :string, nilable: true
              o.default do
                Contrib::SpanAttributeSchema.fetch_service_name(
                  '',
                  Ext::SERVICE_CACHE
                )
              end
            end

            # grouped "cache_key.*" settings
            settings :cache_key do
              # enable or disabling the inclusion of the cache_key in the span
              option :enabled do |o|
                # cache_key.enabled
                o.type :bool
                o.default true
              end
            end

            # Specifies which cache stores to trace.
            # Accepts a list, with the same format as `config.cache_store`
            # (e.g. `memory_store`, `file_store`, or symbols like `:file_store`).
            # Defaults to `nil`, which traces all cache stores.
            # @see https://github.com/rails/rails/blob/b7520a13adda46c0cc5f3fb4a4c1726633af2bba/guides/source/caching_with_rails.md?plain=1#L576-L582
            option :cache_store do |o|
              o.type :array, nilable: true
              o.default nil
              o.after_set do |stores|
                stores&.map!(&:to_s) # Convert symbols to strings to match the Rails configuration format
              end
            end
          end
        end
      end
    end
  end
end
