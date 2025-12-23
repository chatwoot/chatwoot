# frozen_string_literal: true

module Tidewave
  module DatabaseAdapters
    class ActiveRecord < DatabaseAdapter
      RESULT_LIMIT = 50

      def execute_query(query, arguments = [])
        conn = ::ActiveRecord::Base.connection

        # Execute the query with prepared statement and arguments
        if arguments.any?
          result = conn.exec_query(query, "SQL", arguments)
        else
          result = conn.exec_query(query)
        end

        # Format the result
        {
          columns: result.columns,
          rows: result.rows.first(RESULT_LIMIT),
          row_count: result.rows.length,
          adapter: conn.adapter_name,
          database: database_name
        }
      end

      def get_base_class
        ::ActiveRecord::Base
      end

      private

      def database_name
        Rails.configuration.database_configuration.dig(Rails.env, "database")
      end
    end
  end
end
