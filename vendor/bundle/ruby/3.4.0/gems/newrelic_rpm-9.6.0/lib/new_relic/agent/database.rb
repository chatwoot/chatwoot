# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'singleton'
require 'new_relic/agent/database/explain_plan_helpers'
require 'new_relic/agent/database/obfuscator'

module NewRelic
  module Agent
    module Database
      MAX_QUERY_LENGTH = 16384
      ELLIPSIS = '...'.freeze

      extend self

      # Properly encode, truncate, and dup the incoming query.
      # Take care not to the dup the query more than once as
      # correctly encoded may also dup the query.
      def capture_query(query)
        return unless query

        id = query.object_id
        query = Helper.correctly_encoded(truncate_query(query))
        if query.object_id == id
          query.dup
        else
          query
        end
      end

      def truncate_query(query)
        return unless query

        if query.length > (MAX_QUERY_LENGTH - 4)
          query[0..MAX_QUERY_LENGTH - 4] << ELLIPSIS
        else
          query
        end
      end

      def obfuscate_sql(sql)
        Obfuscator.instance.obfuscator.call(sql)
      end

      def set_sql_obfuscator(type, &block)
        Obfuscator.instance.set_sql_obfuscator(type, &block)
      end

      def record_sql_method(config_section = :transaction_tracer)
        key = record_sql_method_key(config_section)

        case Agent.config[key].to_s
        when 'off'
          :off
        when 'none'
          :off
        when 'false'
          :off
        when 'raw'
          :raw
        else
          :obfuscated
        end
      end

      def record_sql_method_key(config_section)
        case config_section
        when :transaction_tracer
          :'transaction_tracer.record_sql'
        when :slow_sql
          :'slow_sql.record_sql'
        else
          "#{config_section}.record_sql".to_sym
        end
      end

      RECORD_FOR = [:raw, :obfuscated].freeze

      def should_record_sql?(config_section = :transaction_tracer)
        RECORD_FOR.include?(record_sql_method(config_section))
      end

      def should_collect_explain_plans?(config_section = :transaction_tracer)
        should_record_sql?(config_section) &&
          Agent.config["#{config_section}.explain_enabled".to_sym]
      end

      def get_connection(config, &connector)
        ConnectionManager.instance.get_connection(config, &connector)
      end

      def close_connections
        ConnectionManager.instance.close_connections
      end

      # Perform this in the runtime environment of a managed
      # application, to explain the sql statement executed within a
      # node of a transaction sample. Returns an array of two arrays.
      # The first array contains the headers, while the second consists of
      # arrays of strings for each column returned by the explain query.
      # Note this happens only for statements whose execution time exceeds
      # a threshold (e.g. 500ms) and only within the slowest transaction
      # in a report period, selected for shipment to New Relic
      def explain_sql(statement)
        return nil unless statement.sql && statement.explainer && statement.config

        statement.sql = statement.sql.split(";\n")[0] # only explain the first
        return statement.explain || []
      end

      KNOWN_OPERATIONS = %w[
        alter
        select
        update
        delete
        insert
        create
        show
        set
        exec
        execute
        call
      ]
      OTHER_OPERATION = 'other'.freeze
      SQL_COMMENT_REGEX = Regexp.new('/\*.*?\*/', Regexp::MULTILINE).freeze

      def parse_operation_from_query(sql)
        sql = Helper.correctly_encoded(sql).gsub(SQL_COMMENT_REGEX, NewRelic::EMPTY_STR)
        return unless sql =~ /(\w+)/

        op = Regexp.last_match(1).downcase
        KNOWN_OPERATIONS.include?(op) ? op : OTHER_OPERATION
      end

      class ConnectionManager
        include Singleton

        # Returns a cached connection for a given ActiveRecord
        # configuration - these are stored or reopened as needed, and if
        # we cannot get one, we ignore it and move on without explaining
        # the sql
        def get_connection(config, &connector)
          @connections ||= {}

          connection = @connections[config]

          return connection if connection

          begin
            @connections[config] = yield(config)
          rescue => e
            ::NewRelic::Agent.logger.error('Caught exception trying to get connection to DB for explain.', e)
            nil
          end
        end

        # Closes all the connections in the internal connection cache
        def close_connections
          @connections ||= {}
          @connections.values.each do |connection|
            begin
              connection.disconnect!
            rescue
            end
          end

          @connections = {}
        end
      end

      class Statement
        include ExplainPlanHelpers

        attr_accessor :sql, :config, :explainer, :binds, :name, :host, :port_path_or_id, :database_name

        DEFAULT_QUERY_NAME = 'SQL'.freeze

        def initialize(sql, config = {}, explainer = nil, binds = nil, name = DEFAULT_QUERY_NAME, host = nil, port_path_or_id = nil, database_name = nil)
          @sql = Database.capture_query(sql)
          @config = config
          @explainer = explainer
          @binds = binds
          @name = name
          @host = host
          @port_path_or_id = port_path_or_id
          @database_name = database_name
          @safe_sql = nil
        end

        # Returns an sql statement that will be in the form most permissable by
        # the config. The format will be safe for transmission to New Relic.
        def safe_sql
          @safe_sql ||= case Database.record_sql_method
            when :obfuscated
              Database.obfuscate_sql(self)
            when :raw
              sql.to_s
          end
        end

        # This takes a connection config hash from ActiveRecord or Sequel and
        # returns a symbol describing the associated database adapter
        def adapter
          return unless @config

          @adapter ||= if @config[:adapter]
            symbolized_adapter(@config[:adapter].to_s.downcase)
          elsif @config[:uri] && @config[:uri].to_s =~ /^jdbc:([^:]+):/
            # This case is for Sequel with the jdbc-mysql, jdbc-postgres, or jdbc-sqlite3 gems.
            symbolized_adapter($1)
          end
        end

        def explain
          return unless explainable?

          handle_exception_in_explain do
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            plan = @explainer.call(self)
            ::NewRelic::Agent.record_metric(
              'Supportability/Database/execute_explain_plan',
              Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
            )
            return process_resultset(plan, adapter) if plan
          end
        end

        NEWLINE = "\n".freeze

        def append_sql(new_sql)
          return if new_sql.empty?

          @sql = Database.truncate_query(@sql << NEWLINE << new_sql)
        end

        private

        POSTGIS_PREFIX = 'postgis'.freeze
        POSTGRES_PREFIX = 'postgres'.freeze
        MYSQL_PREFIX = 'mysql'.freeze
        MYSQL2_PREFIX = 'mysql2'.freeze
        SQLITE_PREFIX = 'sqlite'.freeze

        def symbolized_adapter(adapter)
          if adapter.start_with?(POSTGRES_PREFIX) || adapter == POSTGIS_PREFIX
            :postgres
          elsif adapter == MYSQL_PREFIX
            :mysql
          # For the purpose of fetching explain plans, we need to maintain the distinction
          # between usage of mysql and mysql2. Obfuscation is the same, though.
          elsif adapter == MYSQL2_PREFIX
            :mysql2
          elsif adapter.start_with?(SQLITE_PREFIX)
            :sqlite
          else
            adapter.to_sym
          end
        end

        def explainable?
          return false unless @explainer && is_select?(@sql)

          if @sql.end_with?(ELLIPSIS)
            NewRelic::Agent.logger.debug('Unable to collect explain plan for truncated query.')
            return false
          end

          if parameterized?(@sql) && (!@binds || @binds.empty?)
            NewRelic::Agent.logger.debug('Unable to collect explain plan for parameter-less parameterized query.')
            return false
          end

          if !SUPPORTED_ADAPTERS_FOR_EXPLAIN.include?(adapter)
            NewRelic::Agent.logger.debug("Not collecting explain plan because an unknown connection adapter ('#{adapter}') was used.")
            return false
          end

          if multiple_queries?(@sql)
            NewRelic::Agent.logger.debug('Unable to collect explain plan for multiple queries.')
            return false
          end

          true
        end
      end
    end
  end
end
