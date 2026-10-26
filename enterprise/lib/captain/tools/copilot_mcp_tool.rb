# An MCP tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills a verified parameter with the value it was given, and the result says when that value is not one the customer verified.
class Captain::Tools::CopilotMcpTool < Captain::Tools::McpTool
  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    email_param = @mcp_tool.verified_email_param
    return super unless email_param

    result = super
    verified_email = stored_verified_email(tool_context.state)
    return result if verified_email && params[email_param.to_sym].to_s.strip.casecmp?(verified_email)

    "#{result}\n\n#{Captain::Tools::CopilotHttpTool::UNVERIFIED_VALUE_NOTE}"
  end
end
