# frozen_string_literal: true

require_relative '../../configuration/resolver'
require_relative 'makara_resolver'
require_relative '../../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        module Configuration
          # Converts Symbols, Strings, and Hashes to a normalized connection settings Hash.
          #
          # When matching using a Hash, these are the valid fields:
          # ```
          # {
          #   adapter: ...,
          #   host: ...,
          #   port: ...,
          #   database: ...,
          #   username: ...,
          #   role: ...,
          # }
          # ```
          #
          # Partial matching is supported: not including certain fields or setting them to `nil`
          # will cause them to matching all values for that field. For example: `database: nil`
          # will match any database, given the remaining fields match.
          #
          # Any fields not listed above are discarded.
          #
          # When more than one configuration could be matched, the last one to match is selected,
          # based on addition order (`#add`).
          class Resolver < Contrib::Configuration::Resolver
            prepend MakaraResolver
            prepend Contrib::Configuration::CachingResolver

            def initialize(active_record_configuration = nil)
              super()

              @active_record_configuration = active_record_configuration
            end

            def active_record_configuration
              @active_record_configuration || ::ActiveRecord::Base.configurations
            end

            def add(matcher, value)
              parsed = parse_matcher(matcher)

              # In case of error parsing, don't store `nil` key
              # as it wouldn't be useful for matching configuration
              # hashes in `#resolve`.
              super(parsed, value) if parsed
            end

            def resolve(db_config)
              active_record_config = resolve_connection_key(db_config).symbolize_keys

              hash = normalize_for_resolve(active_record_config)

              # Hashes in Ruby maintain insertion order
              _, config = @configurations.reverse_each.find do |matcher, _|
                matcher.none? do |key, value|
                  value != hash[key]
                end
              end

              config
            rescue => e
              # Resolving a valid database configuration should not raise an exception,
              # but if it does, it can be due to adding a broken pattern match prior to this call.
              #
              # `db_config` input may contain sensitive information such as passwords,
              # hence provide a succinct summary for the error logging.
              #
              Datadog.logger.error(
                'Failed to resolve ActiveRecord database configuration. '\
                "Cause: #{e.class.name} Source: #{Array(e.backtrace).first}"
              )
              Core::Telemetry::Logger.report(e, description: 'Failed to resolve ActiveRecord database configuration')

              nil
            end

            protected

            def parse_matcher(matcher)
              resolved_pattern = resolve_connection_key(matcher).symbolize_keys
              normalized = normalize_for_config(resolved_pattern)

              # Remove empty fields to allow for partial matching
              normalized.reject! { |_, v| v.nil? }

              normalized
            rescue => e
              Datadog.logger.error(
                "Failed to resolve key #{matcher.inspect}. " \
                "Cause: #{e.class.name} Source: #{Array(e.backtrace).first}"
              )
              Core::Telemetry::Logger.report(e, description: 'Failed to resolve key')

              nil
            end

            #
            # `::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver` exists from 4+ til from 6.0.x
            #
            # `::ActiveRecord::DatabaseConfigurations` was introduced from 6+,
            # but from 6.1.x, it was refactored to encapsulates the resolving logic, hence removing the resolver
            #
            def connection_resolver
              @resolver ||=
                # From 6.1+
                if defined?(::ActiveRecord::Base.configurations.resolve)
                  ::ActiveRecord::DatabaseConfigurations.new(active_record_configuration)
                # From 4+ to 6.0.x
                else
                  ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(active_record_configuration)
                end
            end

            def resolve_connection_key(key)
              result = connection_resolver.resolve(key)

              if result.respond_to?(:configuration_hash) # Rails >= 6.1
                result.configuration_hash
              else # Rails < 6.1
                result
              end
            end

            # Extract only fields we'd like to match
            # from the ActiveRecord configuration.
            def normalize_for_config(active_record_config)
              {
                adapter: active_record_config[:adapter],
                host: active_record_config[:host],
                port: active_record_config[:port],
                database: active_record_config[:database],
                username: active_record_config[:username]
              }
            end

            # Both resolvers perform the same operations for this implementation, but can be specialized
            alias_method :normalize_for_resolve, :normalize_for_config
          end
        end
      end
    end
  end
end
