# A tool on an MCP server that an admin approved. Captain::Mcp::AgentTools builds one class per tool from the
# approved definition, so the model sees only the description and schema the admin approved.
class Captain::Tools::McpTool < Captain::Tools::BasePublicTool
  # The most characters of a tool result the model sees
  MAX_RESULT_CHARACTERS = 1.megabyte
  UNAVAILABLE = 'This tool is unavailable right now. Do not call it again in this conversation.'.freeze

  # Whether the model sees and fills a verified parameter. Each subclass answers for the user it serves.
  def self.model_fills_verified_values?
    false
  end

  def initialize(assistant, mcp_tool, connection)
    @mcp_tool = mcp_tool
    @connection = connection
    super(assistant)
  end

  # Each subclass decides the arguments for the user it serves, and can add to the result
  def perform(tool_context, **params)
    arguments = arguments_for(tool_context, params)
    annotate(call_tool(tool_context, arguments), tool_context, params)
  rescue Captain::ParamSources::Unavailable => e
    failure_result(e.message, tool_context.state)
  end

  def read_only?
    @mcp_tool.read_only?
  end

  def for_copilot
    Captain::Mcp::AgentTools.build(@assistant, @mcp_tool, @connection, base_class: Captain::Tools::CopilotMcpTool)
  end

  private

  def arguments_for(_tool_context, _params)
    raise NotImplementedError, "#{self.class} must decide the arguments for the user it serves"
  end

  def annotate(result, _tool_context, _params)
    result
  end

  def call_tool(tool_context, arguments)
    return failure_result(UNAVAILABLE, tool_context.state) unless approved_definition_live?

    result = @connection.call(@mcp_tool.name, arguments)
    return reported_failure(result, tool_context) if result.error?

    result_text(result)
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.error("McpTool error for #{name}: #{e.class} - #{e.message}")
    failure_result('An error occurred while calling the tool', tool_context.state)
  end

  # The server must still offer the definition the admin approved, so a change on the server never reaches Captain. The
  # listing also records each approved tool's review state, so the next run offers a changed tool as unavailable.
  def approved_definition_live?
    definitions = @connection.live_tool_definitions
    @mcp_tool.mcp_server.record_live_tools(definitions)
    live_definition = definitions.find { |definition| definition['name'] == @mcp_tool.name }
    @mcp_tool.review_state_for(live_definition) == 'current'
  end

  # The server ran the tool and reported that it failed. Its text still reaches the model, so Captain can say what went wrong.
  def reported_failure(result, tool_context)
    Rails.logger.warn("McpTool #{name} reported an error")
    text = result_text(result)
    failure_result(text.present? ? "The tool reported an error:\n#{text}" : 'The tool reported an error', tool_context.state)
  end

  def result_text(result)
    text = result.text.presence || (result.structured && JSON.generate(result.structured)).to_s
    text.truncate(MAX_RESULT_CHARACTERS)
  end
end
