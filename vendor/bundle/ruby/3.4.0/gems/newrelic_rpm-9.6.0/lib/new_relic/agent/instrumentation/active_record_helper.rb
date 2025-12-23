# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/datastores/metric_helper'
require 'new_relic/constants'

module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecordHelper
        module_function

        # Used by both the AR 3.x and 4.x instrumentation
        def instrument_additional_methods
          instrument_save_methods
          instrument_relation_methods
        end

        def instrument_save_methods
          ::ActiveRecord::Base.class_eval do
            alias_method(:save_without_newrelic, :save)

            def save(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                save_without_newrelic(*args, &blk)
              end
            end

            alias_method(:save_without_newrelic!, :save!)

            def save!(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                save_without_newrelic!(*args, &blk)
              end
            end
          end
        end

        def instrument_relation_methods
          ::ActiveRecord::Relation.class_eval do
            alias_method(:update_all_without_newrelic, :update_all)

            def update_all(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                update_all_without_newrelic(*args, &blk)
              end
            end

            alias_method(:delete_all_without_newrelic, :delete_all)

            if RUBY_VERSION < '2.7.0'
              def delete_all(*args, &blk)
                ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                  delete_all_without_newrelic(*args, &blk)
                end
              end
            else
              def delete_all(*args, **kwargs, &blk)
                ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                  delete_all_without_newrelic(*args, **kwargs, &blk)
                end
              end
            end

            alias_method(:destroy_all_without_newrelic, :destroy_all)

            def destroy_all(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                destroy_all_without_newrelic(*args, &blk)
              end
            end

            alias_method(:calculate_without_newrelic, :calculate)

            def calculate(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                calculate_without_newrelic(*args, &blk)
              end
            end

            if method_defined?(:pluck)
              alias_method(:pluck_without_newrelic, :pluck)

              def pluck(*args, &blk)
                ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
                  pluck_without_newrelic(*args, &blk)
                end
              end

            end
          end
        end

        ACTIVE_RECORD = 'ActiveRecord'.freeze
        OTHER = 'other'.freeze
        MAKARA_SUFFIX = '_makara'.freeze

        # convert vendor (makara, etc.) wrapper names to their bare names
        # ex: postgresql_makara -> postgresql
        def bare_adapter_name(adapter_name)
          # TODO: OLD RUBIES - RUBY_VERSION < 2.5
          # With Ruby 2.5+ we could use #delete_suffix instead of #chomp for a
          # potential speed boost
          return adapter_name.chomp(MAKARA_SUFFIX) if adapter_name&.end_with?(MAKARA_SUFFIX)

          adapter_name
        end

        def product_operation_collection_for(name, sql, adapter_name)
          product = map_product(bare_adapter_name(adapter_name))
          splits = split_name(name)
          model = model_from_splits(splits)
          operation = operation_from_splits(splits, sql)
          NewRelic::Agent::Datastores::MetricHelper.product_operation_collection_for(product, operation, model, ACTIVE_RECORD)
        end

        SPACE = ' '.freeze

        def split_name(name)
          if name&.respond_to?(:split)
            name.split(SPACE)
          else
            NewRelic::EMPTY_ARRAY
          end
        end

        def model_from_splits(splits)
          if splits.length == 2
            splits.first
          end
        end

        def operation_from_splits(splits, sql)
          if splits.length == 2
            map_operation(splits[1])
          else
            NewRelic::Agent::Database.parse_operation_from_query(sql) || OTHER
          end
        end

        # These are used primarily to optimize and avoid allocation on well
        # known operations coming in. Anything not matching the list is fine,
        # it just needs to get downcased directly for use.
        OPERATION_NAMES = {
          'Find' => 'find',
          'Load' => 'find',
          'Count' => 'find',
          'Exists' => 'find',
          'Create' => 'create',
          'Columns' => 'columns',
          'Indexes' => 'indexes',
          'Destroy' => 'destroy',
          'Update' => 'update',
          'Save' => 'save'
        }.freeze

        def map_operation(raw_operation)
          direct_op = OPERATION_NAMES[raw_operation]
          return direct_op if direct_op

          raw_operation.downcase
        end

        PRODUCT_NAMES = {
          'mysql' => 'MySQL',
          'mysql2' => 'MySQL',

          'postgresql' => 'Postgres',

          'sqlite3' => 'SQLite',

          # https://rubygems.org/gems/activerecord-jdbcpostgresql-adapter
          'jdbcmysql' => 'MySQL',

          # https://rubygems.org/gems/activerecord-jdbcpostgresql-adapter
          'jdbcpostgresql' => 'Postgres',

          # https://rubygems.org/gems/activerecord-postgis-adapter
          'postgis' => 'Postgres',

          # https://rubygems.org/gems/activerecord-jdbcsqlite3-adapter
          'jdbcsqlite3' => 'SQLite',

          # https://rubygems.org/gems/activerecord-jdbcderby-adapter
          'derby' => 'Derby',
          'jdbcderby' => 'Derby',

          # https://rubygems.org/gems/activerecord-jdbc-adapter
          'jdbc' => 'JDBC',

          # https://rubygems.org/gems/activerecord-jdbcmssql-adapter
          'jdbcmssql' => 'MSSQL',
          'mssql' => 'MSSQL',

          # https://rubygems.org/gems/activerecord-sqlserver-adapter
          'sqlserver' => 'MSSQL',

          # https://rubygems.org/gems/activerecord-odbc-adapter
          'odbc' => 'ODBC',

          # https://rubygems.org/gems/activerecord-oracle_enhanced-adapter
          'oracle_enhanced' => 'Oracle',

          # https://rubygems.org/gems/activerecord-amazon-timestream-adapter
          'amazon_timestream' => 'Timestream'
        }.freeze

        ACTIVE_RECORD_DEFAULT_PRODUCT_NAME = 'ActiveRecord'.freeze

        def map_product(adapter_name)
          PRODUCT_NAMES.fetch(adapter_name, ACTIVE_RECORD_DEFAULT_PRODUCT_NAME)
        end

        module InstanceIdentification
          extend self

          PRODUCT_SYMBOLS = {
            'mysql' => :mysql,
            'mysql2' => :mysql,
            'jdbcmysql' => :mysql,

            'postgresql' => :postgres,
            'jdbcpostgresql' => :postgres,
            'postgis' => :postgres
          }.freeze

          DATASTORE_DEFAULT_PORTS = {
            :mysql => '3306',
            :postgres => '5432'
          }.freeze

          DEFAULT = 'default'.freeze
          UNKNOWN = 'unknown'.freeze
          LOCALHOST = 'localhost'.freeze

          def adapter_from_config(config)
            bare_name = NewRelic::Agent::Instrumentation::ActiveRecordHelper.bare_adapter_name(config[:adapter])
            PRODUCT_SYMBOLS[bare_name]
          end

          def host(config)
            return UNKNOWN unless config

            configured_value = config[:host]
            adapter = adapter_from_config(config)
            if configured_value.nil? ||
                postgres_unix_domain_socket_case?(configured_value, adapter)

              LOCALHOST
            elsif configured_value.empty?
              UNKNOWN
            else
              configured_value
            end
          rescue => e
            NewRelic::Agent.logger.debug("Failed to retrieve ActiveRecord host: #{e}")
            UNKNOWN
          end

          def port_path_or_id(config)
            return UNKNOWN unless config

            adapter = adapter_from_config(config)
            if config[:socket]
              config[:socket].empty? ? UNKNOWN : config[:socket]
            elsif postgres_unix_domain_socket_case?(config[:host], adapter) || mysql_default_case?(config, adapter)
              DEFAULT
            elsif config[:port].nil?
              DATASTORE_DEFAULT_PORTS[adapter] || DEFAULT
            elsif config[:port].is_a?(Integer) || config[:port].to_i != 0
              config[:port].to_s
            else
              UNKNOWN
            end
          rescue => e
            NewRelic::Agent.logger.debug("Failed to retrieve ActiveRecord port_path_or_id: #{e}")
            UNKNOWN
          end

          SUPPORTED_ADAPTERS = [:mysql, :postgres].freeze

          def supported_adapter?(config)
            config && SUPPORTED_ADAPTERS.include?(adapter_from_config(config))
          end

          private

          def postgres_unix_domain_socket_case?(host, adapter)
            adapter == :postgres && host && host.start_with?(NewRelic::SLASH)
          end

          def mysql_default_case?(config, adapter)
            (adapter == :mysql2 || adapter == :mysql) &&
              Hostname.local?(config[:host]) &&
              !config[:port]
          end
        end
      end
    end
  end
end
