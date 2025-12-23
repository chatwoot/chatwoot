# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/database/obfuscator'
require 'new_relic/agent/database/postgres_explain_obfuscator'

module NewRelic
  module Agent
    module Database
      module ExplainPlanHelpers
        SUPPORTED_ADAPTERS_FOR_EXPLAIN = [:postgres, :mysql2, :mysql, :sqlite]
        SELECT = 'select'.freeze

        def is_select?(sql)
          NewRelic::Agent::Database.parse_operation_from_query(sql) == SELECT
        end

        def parameterized?(sql)
          Obfuscator.instance.obfuscate_single_quote_literals(sql) =~ /\$\d+/
        end

        # SQL containing a semicolon in the middle (with something
        # other than whitespace after it) may contain two or more
        # queries.  It's not safe to EXPLAIN this kind of expression,
        # since it could lead to executing unwanted SQL.
        #
        MULTIPLE_QUERIES = Regexp.new(';\s*\S+')

        def multiple_queries?(sql)
          sql =~ MULTIPLE_QUERIES
        end

        def handle_exception_in_explain
          yield
        rescue => e
          begin
            # guarantees no throw from explain_sql
            ::NewRelic::Agent.logger.error('Error getting query plan:', e)
            nil
          rescue
            # double exception. throw up your hands
            nil
          end
        end

        def process_resultset(results, adapter)
          if adapter == :postgres
            return process_explain_results_postgres(results)
          elsif defined?(::ActiveRecord::Result) && results.is_a?(::ActiveRecord::Result)
            # Note if adapter is mysql, will only have headers, not values
            return [results.columns, results.rows]
          elsif results.is_a?(String)
            return string_explain_plan_results(results)
          end

          case adapter
          when :mysql2
            process_explain_results_mysql2(results)
          when :mysql
            process_explain_results_mysql(results)
          when :sqlite
            process_explain_results_sqlite(results)
          end
        end

        QUERY_PLAN = 'QUERY PLAN'.freeze

        def process_explain_results_postgres(results)
          if defined?(::ActiveRecord::Result) && results.is_a?(::ActiveRecord::Result)
            query_plan_string = results.rows.join("\n")
          elsif results.is_a?(String)
            query_plan_string = results
          else
            lines = []
            results.each { |row| lines << row[QUERY_PLAN] }
            query_plan_string = lines.join("\n")
          end

          unless NewRelic::Agent::Database.record_sql_method == :raw
            query_plan_string = NewRelic::Agent::Database::PostgresExplainObfuscator.obfuscate(query_plan_string)
          end
          values = query_plan_string.split("\n").map { |line| [line] }

          [[QUERY_PLAN], values]
        end

        # Sequel returns explain plans as just one big pre-formatted String
        # In that case, we send a nil headers array, and the single string
        # wrapped in an array for the values.
        # Note that we don't use this method for Postgres explain plans, since
        # they need to be passed through the explain plan obfuscator first.
        def string_explain_plan_results(results)
          [nil, [results]]
        end

        def process_explain_results_mysql(results)
          headers = []
          values = []
          if results.is_a?(Array)
            # We're probably using the jdbc-mysql gem for JRuby, which will give
            # us an array of hashes.
            headers = results.first.keys
            results.each do |row|
              values << headers.map { |h| row[h] }
            end
          else
            # We're probably using the native mysql driver gem, which will give us
            # a Mysql::Result object that responds to each_hash
            results.each_hash do |row|
              headers = row.keys
              values << headers.map { |h| row[h] }
            end
          end
          [headers, values]
        end

        def process_explain_results_mysql2(results)
          headers = results.fields
          values = []
          results.each { |row| values << row }
          [headers, values]
        end

        SQLITE_EXPLAIN_COLUMNS = %w[addr opcode p1 p2 p3 p4 p5 comment]

        def process_explain_results_sqlite(results)
          headers = SQLITE_EXPLAIN_COLUMNS
          values = []
          results.each do |row|
            values << headers.map { |h| row[h] }
          end
          [headers, values]
        end
      end
    end
  end
end
