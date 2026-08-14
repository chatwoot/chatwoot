class Captain::Routines::Tools::DescribeOperations < Captain::Routines::Tools::Base
  description 'Inspect the executable Captain Routine operation catalog by operation name, argument, or product behavior'
  param :query, type: 'string', desc: 'Operation name or product behavior to look up; use all to list the complete catalog'

  def name = 'describe_operations'

  def perform(_tool_context, query:)
    normalized_query = query.downcase
    operations = Captain::Routines::Operations::Registry::OPERATIONS
    matches = operations.select do |name, operation|
      normalized_query == 'all' || [name, operation.description, operation.arguments.to_json].any? do |value|
        value.downcase.include?(normalized_query)
      end
    end

    matches.transform_values(&:definition).to_json
  end
end
