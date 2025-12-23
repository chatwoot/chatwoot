# frozen_string_literal: true

require "test_prof/any_fixture/dump/base_adapter"

module TestProf
  module AnyFixture
    class Dump
      class SQLite < BaseAdapter
        def reset_sequence!(table_name, start)
          execute <<~SQL.chomp
            DELETE FROM sqlite_sequence WHERE name=#{table_name}
          SQL

          execute <<~SQL.chomp
            INSERT INTO sqlite_sequence (name, seq)
            VALUES (#{table_name}, #{start})
          SQL
        end

        def compile_sql(sql, binds)
          sql.gsub(/\?/) { binds.shift.gsub("\n", "' || char(10) || '") }
        end

        def import(path)
          db = conn.pool.spec.config[:database]
          return false if %r{:memory:}.match?(db)

          # Check that sqlite3 is installed
          `sqlite3 --version`

          while_disconnected do
            `sqlite3 #{db} < "#{path}"`
          end

          true
        rescue Errno::ENOENT
          false
        end
      end
    end
  end
end
