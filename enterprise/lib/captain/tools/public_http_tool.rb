# A custom tool in a conversation where a customer is the user. Parameters with a source always carry the value
# Chatwoot read from what the customer proved, and the tool does not run when that value is missing.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  def perform(tool_context, **params)
    arguments = Captain::ToolArguments.new(@custom_tool, find_conversation(tool_context.state)).fill(params)
    super(tool_context, **arguments)
  rescue Captain::ParamSources::Unavailable => e
    failure_result(e.message, tool_context.state)
  end
end
