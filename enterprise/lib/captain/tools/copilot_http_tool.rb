# A custom tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills sourced parameters with the values it was given, and the result says when they are not the ones the customer proved.
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  UNVERIFIED_VALUE_NOTE = 'A value passed to this tool was not verified by the customer.'.freeze

  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    result = super
    arguments = Captain::ToolArguments.new(@custom_tool, find_conversation(tool_context.state))
    arguments.verified?(params) ? result : "#{result}\n\n#{UNVERIFIED_VALUE_NOTE}"
  end
end
