# frozen_string_literal: true

class Tidewave::Tools::ExecuteSqlQuery < Tidewave::Tools::Base
  tool_name "execute_sql_query"
  description <<~DESCRIPTION
    Executes the given SQL query against the database connection.
    Returns the result as a Ruby data structure.

    Note that the output is limited to 50 rows at a time. If you need to see more, perform additional calls
    using LIMIT and OFFSET in the query. If you know that only specific columns are relevant,
    only include those in the SELECT clause.

    You can use this tool to select user data, manipulate entries, and introspect the application data domain.
    Always ensure to use the correct SQL commands for the database you are using.

    For PostgreSQL, use $1, $2, etc. for parameter placeholders.
    For MySQL, use ? for parameter placeholders.
  DESCRIPTION

  arguments do
    required(:query).filled(:string).description("The SQL query to execute. For PostgreSQL, use $1, $2 placeholders. For MySQL, use ? placeholders.")
    optional(:arguments).value(:array).description("The arguments to pass to the query. The query must contain corresponding parameter placeholders.")
  end

  RESULT_LIMIT = 50

  def call(query:, arguments: [])
    Tidewave::DatabaseAdapter.current.execute_query(query, arguments)
  end
end
