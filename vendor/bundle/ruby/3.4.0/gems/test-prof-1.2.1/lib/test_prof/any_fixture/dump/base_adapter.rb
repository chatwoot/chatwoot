# frozen_string_literal: true

module TestProf
  module AnyFixture
    class Dump
      class BaseAdapter
        def reset_sequence!(_table_name, _start)
        end

        def compile_sql(sql, _binds)
          sql
        end

        def setup_env
        end

        def teardown_env
        end

        def import(_path)
          false
        end

        private

        def while_disconnected
          conn.disconnect!
          yield
        ensure
          conn.reconnect!
        end

        def conn
          ActiveRecord::Base.connection
        end

        def execute(query)
          conn.execute(query)
        end
      end
    end
  end
end
