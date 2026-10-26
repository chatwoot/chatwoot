# A read tool on an MCP server that an admin approved. Captain::Mcp::AgentTools builds one class per tool from the
# approved definition, so the model sees only the description and schema the admin approved.
class Captain::Tools::McpTool < Captain::Tools::BasePublicTool
  attr_reader :mcp_server, :mcp_tool, :connection

  # Whether the model sees and fills a verified parameter. Each subclass answers for the user it serves.
  def self.model_fills_verified_values?
    false
  end

  def initialize(assistant, mcp_server, mcp_tool, connection)
    @mcp_server = mcp_server
    @mcp_tool = mcp_tool
    @connection = connection
    super(assistant)
  end

  def perform(tool_context, **params)
    # Fixed values go last, so a value from the model can never replace them
    result = @connection.call(@mcp_tool.name, params.merge(fixed_arguments))
    untrusted_result(result_text(result))
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.error("McpTool error for #{name}: #{e.class} - #{e.message}")
    failure_result('An error occurred while calling the tool', tool_context.state)
  end

  def available_in_reply_suggestion?
    true
  end

  private

  # Captain uses read tools only, so a newer customer message is no reason to skip one
  def safe_to_run_after_new_customer_message?
    true
  end

  def fixed_arguments
    @mcp_tool.param_sources.filter_map do |param_name, source|
      [param_name.to_sym, source['value']] if source['source'] == Captain::McpTool::PARAM_SOURCE_FIXED
    end.to_h
  end

  def result_text(result)
    text = result.text.presence || (result.structured && JSON.generate(result.structured)).to_s
    text.truncate(Captain::Tools::HttpTool::MAX_RESPONSE_SIZE)
  end
end
