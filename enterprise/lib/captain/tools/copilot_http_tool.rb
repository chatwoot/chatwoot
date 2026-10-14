# A custom tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills verified parameters, and a value the customer verified is still used in its place.
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  # The model supplied a verified value, so the result says nobody verified it
  UNVERIFIED_VALUE_NOTE = 'The email or identifier passed to this tool was not verified by the customer.'.freeze

  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    verified_values = stored_verified_values(tool_context.state)
    supplied = @custom_tool.param_schema.select { |param_def| param_def['source'] && verified_values.exclude?(param_def['source']) }
    missing = supplied.select { |param_def| params[param_def['name'].to_sym].blank? }
    return failure_result(missing_value_message(missing), tool_context.state) if missing.any?

    result = super(tool_context, **@custom_tool.with_verified_values(params, verified_values).symbolize_keys)
    supplied.any? ? "#{result}\n\n#{UNVERIFIED_VALUE_NOTE}" : result
  end

  private

  def missing_value_message(missing)
    "This tool needs the customer's #{missing.pluck('name').join(', ')}. Pass it as a parameter."
  end
end
