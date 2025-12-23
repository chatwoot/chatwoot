# frozen_string_literal: true

require "test_prof/any_fixture/dump/base_adapter"

module TestProf
  module AnyFixture
    class Dump
      class PostgreSQL < BaseAdapter
        UUID_FUNCTIONS = %w[
          gen_random_uuid
          uuid_generate_v4
        ]

        def reset_sequence!(table_name, start)
          _pk, sequence = conn.pk_and_sequence_for(table_name)
          return unless sequence

          sequence_name = "#{sequence.schema}.#{sequence.identifier}"

          execute <<~SQL
            ALTER SEQUENCE #{sequence_name} RESTART WITH #{start}; -- any_fixture:dump
          SQL
        end

        def compile_sql(sql, binds)
          sql.gsub(/\$\d+/) { binds.shift.gsub("\n", "' || chr(10) || '") }
        end

        def import(path)
          # Test if psql is installed
          `psql --version`

          tasks = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config)

          while_disconnected do
            tasks.structure_load(path, "--output=/dev/null")
          end

          true
        rescue Errno::ENOENT
          false
        end

        def setup_env
          # Mock UUID generating functions to provide consistent results
          quoted_functions = UUID_FUNCTIONS.map { |func| "'#{func}'" }.join(", ")

          @uuid_funcs = execute <<~SQL
            SELECT
              pp.proname, pn.nspname,
              pg_get_functiondef(pp.oid) AS definition
            FROM pg_proc pp
            JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
            WHERE pp.proname in (#{quoted_functions})
            ORDER BY pp.oid;
          SQL

          uuid_funcs.each do |(func, ns, _)|
            execute <<~SQL
              CREATE OR REPLACE FUNCTION #{ns}.#{func}()
                RETURNS UUID
                LANGUAGE SQL
                AS $$
                  SELECT md5(random()::TEXT)::UUID;
                $$; -- any_fixture:dump
            SQL
          end

          execute <<~SQL
            SELECT setseed(#{rand}); -- any_fixture:dump
          SQL
        end

        def teardown_env
          uuid_funcs.each do |(func, ns, definition)|
            execute "#{definition}; -- any_fixture:dump"
          end
        end

        private

        attr_reader :uuid_funcs

        def execute(query)
          super.values
        end

        def config
          conn_pool = conn.pool
          if conn_pool.respond_to?(:spec) # Support for Rails < 6.1
            conn_pool.spec.config
          else
            conn_pool.db_config
          end
        end
      end
    end
  end
end
