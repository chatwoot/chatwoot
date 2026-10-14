# A custom tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills verified parameters with the value it was given, and the result says when that value is not one the customer verified.
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  UNVERIFIED_VALUE_NOTE = 'The email or identifier passed to this tool was not verified by the customer.'.freeze

  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    missing = verified_params.select { |param_def| params[param_def['name'].to_sym].blank? }
    return failure_result(missing_value_message(missing), tool_context.state) if missing.any?

    result = super
    unverified_value?(tool_context, params) ? "#{result}\n\n#{UNVERIFIED_VALUE_NOTE}" : result
  end

  private

  def verified_params
    @custom_tool.param_schema.select { |param_def| param_def['source'] }
  end

  def unverified_value?(tool_context, params)
    verified_values = stored_verified_values(tool_context.state)
    verified_params.any? { |param_def| !params[param_def['name'].to_sym].to_s.strip.casecmp?(verified_values[param_def['source']].to_s) }
  end

  def missing_value_message(missing)
    "This tool needs the customer's #{missing.pluck('name').join(', ')}. Pass it as a parameter."
  end
end
