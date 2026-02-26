class Captain::Mcp::Error < StandardError; end
class Captain::Mcp::ConnectionError < Captain::Mcp::Error; end
class Captain::Mcp::ProtocolError < Captain::Mcp::Error; end
class Captain::Mcp::AuthenticationError < Captain::Mcp::Error; end
class Captain::Mcp::TimeoutError < Captain::Mcp::Error; end
class Captain::Mcp::ToolExecutionError < Captain::Mcp::Error; end

module Captain::Mcp::Errors
  Error = Captain::Mcp::Error
  ConnectionError = Captain::Mcp::ConnectionError
  ProtocolError = Captain::Mcp::ProtocolError
  AuthenticationError = Captain::Mcp::AuthenticationError
  TimeoutError = Captain::Mcp::TimeoutError
  ToolExecutionError = Captain::Mcp::ToolExecutionError
end
