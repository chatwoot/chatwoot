# A tool on an MCP server that an admin approved. Captain::Mcp::AgentTools builds one class per tool from the
# approved definition, so the model sees only the description and schema the admin approved.
class Captain::Tools::McpTool < Captain::Tools::BasePublicTool
  # The most characters of a tool result the model sees
  MAX_RESULT_CHARACTERS = 1.megabyte

  attr_reader :mcp_tool, :connection

  # Whether the model sees and fills a verified parameter. Each subclass answers for the user it serves.
  def self.model_fills_verified_values?
    false
  end

  def initialize(assistant, mcp_tool, connection)
    @mcp_tool = mcp_tool
    @connection = connection
    super(assistant)
  end

  # Each subclass fills the sourced parameters for the user it serves before it calls this
  def perform(tool_context, **params)
    result = @connection.call(@mcp_tool.name, params)
    untrusted_result(result_text(result))
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.error("McpTool error for #{name}: #{e.class} - #{e.message}")
    failure_result('An error occurred while calling the tool', tool_context.state)
  end

  def available_in_reply_suggestion?
    @mcp_tool.read_only?
  end

  private

  def safe_to_run_after_new_customer_message?
    @mcp_tool.read_only?
  end

  def result_text(result)
    text = result.text.presence || (result.structured && JSON.generate(result.structured)).to_s
    text.truncate(MAX_RESULT_CHARACTERS)
  end
end
