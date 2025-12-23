require "delegate"
require 'active_record/base'
require 'database_cleaner/active_record/base'

module DatabaseCleaner
  module ActiveRecord
    class Truncation < Base
      def initialize(opts={})
        if !opts.empty? && !(opts.keys - [:only, :except, :pre_count, :cache_tables]).empty?
          raise ArgumentError, "The only valid options are :only, :except, :pre_count, and :cache_tables. You specified #{opts.keys.join(',')}."
        end

        @only = Array(opts[:only]).dup
        @except = Array(opts[:except]).dup

        @pre_count = opts[:pre_count]
        @cache_tables = opts.has_key?(:cache_tables) ? !!opts[:cache_tables] : true
      end

      def clean
        connection.disable_referential_integrity do
          if pre_count? && connection.respond_to?(:pre_count_truncate_tables)
            connection.pre_count_truncate_tables(tables_to_truncate(connection))
          else
            connection.truncate_tables(tables_to_truncate(connection))
          end
        end
      end

      private

      def connection
        @connection ||= ConnectionWrapper.new(connection_class.connection)
      end

      def tables_to_truncate(connection)
        if @only.none?
          all_tables = cache_tables? ? connection.database_cleaner_table_cache : connection.database_tables
          @only = all_tables.map { |table| table.split(".").last }
        end
        @except += connection.database_cleaner_view_cache + migration_storage_names
        @only - @except
      end

      def migration_storage_names
        [
          DatabaseCleaner::ActiveRecord::Base.migration_table_name,
          ::ActiveRecord::Base.internal_metadata_table_name,
        ]
      end

      def cache_tables?
        !!@cache_tables
      end

      def pre_count?
        @pre_count == true
      end
    end

    class ConnectionWrapper < SimpleDelegator
      def initialize(connection)
        extend AbstractAdapter
        case connection.adapter_name
        when "Mysql2"
          extend AbstractMysqlAdapter
        when "SQLite"
          extend AbstractMysqlAdapter
          extend SQLiteAdapter
        when "PostgreSQL", "PostGIS"
          extend AbstractMysqlAdapter
          extend PostgreSQLAdapter
        end
        super(connection)
      end

      module AbstractAdapter
        # used to be called views but that can clash with gems like schema_plus
        # this gem is not meant to be exposing such an extra interface any way
        def database_cleaner_view_cache
          @views ||= select_values("select table_name from information_schema.views where table_schema = '#{current_database}'") rescue []
        end

        def database_cleaner_table_cache
          # the adapters don't do caching (#130) but we make the assumption that the list stays the same in tests
          @database_cleaner_tables ||= database_tables
        end

        def database_tables
          tables
        end

        def truncate_table(table_name)
          execute("TRUNCATE TABLE #{quote_table_name(table_name)}")
        rescue ::ActiveRecord::StatementInvalid
          execute("DELETE FROM #{quote_table_name(table_name)}")
        end

        def truncate_tables(tables)
          tables.each { |t| truncate_table(t) }
        end
      end

      module AbstractMysqlAdapter
        def pre_count_truncate_tables(tables)
          truncate_tables(pre_count_tables(tables))
        end

        def pre_count_tables(tables)
          tables.select { |table| has_been_used?(table) }
        end

        private

        def row_count(table)
          select_value("SELECT EXISTS (SELECT 1 FROM #{quote_table_name(table)} LIMIT 1)")
        end

        def auto_increment_value(table)
          select_value(<<-SQL).to_i
            SELECT auto_increment
            FROM information_schema.tables
            WHERE table_name = '#{table}'
            AND table_schema = database()
          SQL
        end

        # This method tells us if the given table has been inserted into since its
        # last truncation. Note that the table might have been populated, which
        # increased the auto-increment counter, but then cleaned again such that
        # it appears empty now.
        def has_been_used?(table)
          has_rows?(table) || auto_increment_value(table) > 1
        end

        def has_rows?(table)
          row_count(table) > 0
        end
      end

      module SQLiteAdapter
        def truncate_table(table_name)
          super
          if uses_sequence?
            execute("DELETE FROM sqlite_sequence where name = '#{table_name}';")
          end
        end

        def truncate_tables(tables)
          tables.each { |t| truncate_table(t) }
        end

        def pre_count_truncate_tables(tables)
          truncate_tables(pre_count_tables(tables))
        end

        def pre_count_tables(tables)
          sequences = fetch_sequences
          tables.select { |table| has_been_used?(table, sequences) }
        end

        private

        def fetch_sequences
          return {} unless uses_sequence?
          results = select_all("SELECT * FROM sqlite_sequence")
          Hash[results.rows]
        end

        def has_been_used?(table, sequences)
          count = sequences.fetch(table) { row_count(table) }
          count > 0
        end

        def row_count(table)
          select_value("SELECT EXISTS (SELECT 1 FROM #{quote_table_name(table)} LIMIT 1)")
        end

        # Returns a boolean indicating if the SQLite database is using the sqlite_sequence table.
        def uses_sequence?
          select_value("SELECT name FROM sqlite_master WHERE type='table' AND name='sqlite_sequence';")
        end
      end

      module PostgreSQLAdapter
        def database_tables
          tables_with_schema
        end

        def truncate_tables(table_names)
          return if table_names.nil? || table_names.empty?
          execute("TRUNCATE TABLE #{table_names.map{|name| quote_table_name(name)}.join(', ')} RESTART IDENTITY RESTRICT;")
        end

        def pre_count_truncate_tables(tables)
          truncate_tables(pre_count_tables(tables))
        end

        def pre_count_tables(tables)
          tables.select { |table| has_been_used?(table) }
        end

        def database_cleaner_table_cache
          # AR returns a list of tables without schema but then returns a
          # migrations table with the schema. There are other problems, too,
          # with using the base list. If a table exists in multiple schemas
          # within the search path, truncation without the schema name could
          # result in confusing, if not unexpected results.
          @database_cleaner_tables ||= tables_with_schema
        end

        private

        # Returns a boolean indicating if the given table has an auto-inc number higher than 0.
        # Note, this is different than an empty table since an table may populated, the index increased,
        # but then the table is cleaned.  In other words, this function tells us if the given table
        # was ever inserted into.
        def has_been_used?(table)
          return has_rows?(table) unless has_sequence?(table)

          cur_val = select_value("SELECT currval('#{table}_id_seq');").to_i rescue 0
          cur_val > 0
        end

        def has_sequence?(table)
          select_value("SELECT true FROM pg_class WHERE relname = '#{table}_id_seq';")
        end

        def has_rows?(table)
          select_value("SELECT true FROM #{table} LIMIT 1;")
        end

        def tables_with_schema
          rows = select_rows <<-_SQL
            SELECT schemaname || '.' || tablename
            FROM pg_tables
            WHERE
              tablename !~ '_prt_' AND
              #{DatabaseCleaner::ActiveRecord::Base.exclusion_condition('tablename')} AND
              schemaname = ANY (current_schemas(false))
          _SQL
          rows.collect { |result| result.first }
        end
      end
    end
    private_constant :ConnectionWrapper
  end
end

