# Runs a tool in a conversation where a customer is the user. Parameters with a source always carry the value
# Chatwoot read from what the customer proved, and the tool does not run when that value is missing.
# The including class answers sourced_tool with the record that lists its sources.
module Captain::Tools::PublicSourcedArguments
  def perform(tool_context, **params)
    arguments = Captain::ToolArguments.new(sourced_tool, find_conversation(tool_context.state)).fill(params)
    super(tool_context, **arguments)
  rescue Captain::ParamSources::Unavailable => e
    failure_result(e.message, tool_context.state)
  end
end
