# A tool on an MCP server that an admin approved. Captain::Mcp::AgentTools builds one class per tool from the
# approved definition, so the model sees only the description and schema the admin approved.
class Captain::Tools::McpTool < Captain::Tools::BasePublicTool
  # The most characters of a tool result the model sees
  MAX_RESULT_CHARACTERS = 1.megabyte
  UNAVAILABLE = 'This tool is unavailable right now. Do not call it again in this conversation.'.freeze
  OUTCOME_UNKNOWN = 'The tool did not finish answering, and it may have run. Do not call it again in this conversation.'.freeze
  # Failures that come after the server received the call, so a tool that changes data may have run
  UNREAD_ANSWER_ERRORS = [Captain::Mcp::Connection::DeadlineExceeded, Captain::Mcp::SafeFaradayAdapter::ResponseTooLarge,
                          Faraday::TimeoutError].freeze

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

  # The listing and the call each have their own deadline, so a slow listing never cuts the answer of a call the
  # server already ran
  def call_tool(tool_context, arguments)
    definitions = @mcp_tool.mcp_server.refresh_live_tools(@connection)
    return failure_result(UNAVAILABLE, tool_context.state) unless approved_definition_in?(definitions)
    # The listing can take a while, so a tool that changes data checks again right before it runs
    return failure_result(NEWER_MESSAGE_ARRIVED, tool_context.state) if !read_only? && newer_customer_message_arrived?(tool_context.state)

    call_server(tool_context, arguments)
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.error("McpTool error for #{name}: #{e.class} - #{e.message}")
    failure_result('An error occurred while calling the tool', tool_context.state)
  end

  # The call records what it says about the credentials, as a listing does, so a refused call reaches the server card.
  # A tool that changes data may have run when its answer stops arriving, so the model must not call it again.
  def call_server(tool_context, arguments)
    result = @connection.track_status { @connection.call(@mcp_tool.name, arguments) }
    return reported_failure(result, tool_context) if result.error?

    result_text(result)
  rescue *UNREAD_ANSWER_ERRORS => e
    raise if read_only?

    Rails.logger.error("McpTool #{name} may have run without an answer: #{e.class} - #{e.message}")
    failure_result(OUTCOME_UNKNOWN, tool_context.state)
  end

  # The server must still offer the definition the admin approved, so a change on the server never reaches Captain.
  # The listing before this records each approved tool's review state, so the server card shows a change and clears it
  # once the server offers the approved definition again.
  def approved_definition_in?(definitions)
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
