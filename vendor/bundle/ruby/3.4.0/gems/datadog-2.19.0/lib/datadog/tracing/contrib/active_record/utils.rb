# frozen_string_literal: true

require_relative '../../../core/environment/ext'
require_relative '../utils/database'

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        # Common utilities for Rails
        module Utils
          EMPTY_CONFIG = {}.freeze

          def self.adapter_name
            Contrib::Utils::Database.normalize_vendor(connection_config[:adapter])
          end

          def self.database_name
            connection_config[:database]
          end

          def self.adapter_host
            connection_config[:host]
          end

          def self.adapter_port
            connection_config[:port]
          end

          # Returns the connection configuration hash from the
          # current connection
          #
          # Since Rails 6.0, we have direct access to the object,
          # while older versions of Rails only provide us the
          # connection id.
          #
          # @see https://github.com/rails/rails/pull/34602
          def self.connection_config(connection = nil, connection_id = nil)
            return default_connection_config if connection.nil? && connection_id.nil?

            conn = if !connection.nil?
                     # Since Rails 6.0, the connection object
                     # is directly available.
                     connection
                   else
                     # For Rails < 6.0, only the `connection_id`
                     # is available. We have to find the connection
                     # object from it.
                     connection_from_id(connection_id)
                   end

            if conn && conn.instance_variable_defined?(:@config)
              conn.instance_variable_get(:@config)
            else
              EMPTY_CONFIG
            end
          end

          # DEV: JRuby responds to {ObjectSpace._id2ref}, despite raising an error
          # DEV: when invoked. Thus, we have to explicitly check for Ruby runtime.
          if Core::Environment::Ext::RUBY_ENGINE != 'jruby'
            # CRuby has access to {ObjectSpace._id2ref}, which allows for
            # direct look up of the connection object.
            def self.connection_from_id(connection_id)
              # `connection_id` is the `#object_id` of the
              # connection. We can perform an ObjectSpace
              # lookup to find it.
              #
              # This works not only for ActiveRecord, but for
              # extensions that might have their own connection
              # pool (e.g. https://rubygems.org/gems/makara).
              ObjectSpace._id2ref(connection_id)
            rescue => e
              # Because `connection_id` references a live connection
              # present in the current stack, it is very unlikely that
              # `_id2ref` will fail, but we add this safeguard just
              # in case.
              Datadog.logger.debug(
                "connection_id #{connection_id} does not represent a valid object. " \
                        "Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
              )
            end
          else
            # JRuby does not enable {ObjectSpace._id2ref} by default,
            # as it has large performance impact:
            # https://github.com/jruby/jruby/wiki/PerformanceTuning/cf155dd9#dont-enable-objectspace
            #
            # This fallback code does not support the makara gem,
            # as its connections don't live in the ActiveRecord
            # connection pool.
            def self.connection_from_id(connection_id)
              ::ActiveRecord::Base
                .connection_handler
                .connection_pool_list
                .flat_map(&:connections)
                .find { |c| c.object_id == connection_id }
            end
          end

          # @return [Hash]
          def self.default_connection_config
            return @default_connection_config if instance_variable_defined?(:@default_connection_config)

            current_connection_name = if ::ActiveRecord::Base.respond_to?(:connection_specification_name)
                                        ::ActiveRecord::Base.connection_specification_name
                                      else
                                        ::ActiveRecord::Base
                                      end

            connection_pool = ::ActiveRecord::Base.connection_handler.retrieve_connection_pool(current_connection_name)
            connection_pool.nil? ? EMPTY_CONFIG : (@default_connection_config = db_config(connection_pool))
          rescue StandardError
            EMPTY_CONFIG
          end

          # @return [Hash]
          def self.db_config(connection_pool)
            if connection_pool.respond_to? :db_config
              connection_pool.db_config.configuration_hash
            else
              connection_pool.spec.config
            end
          end
        end
      end
    end
  end
end
