module Captain
  module Mcp
    class Error < StandardError; end
    class ConnectionError < Error; end
    class ProtocolError < Error; end
    class AuthenticationError < Error; end
    class TimeoutError < Error; end
    class ToolExecutionError < Error; end

    module Errors
      Error = Captain::Mcp::Error
      ConnectionError = Captain::Mcp::ConnectionError
      ProtocolError = Captain::Mcp::ProtocolError
      AuthenticationError = Captain::Mcp::AuthenticationError
      TimeoutError = Captain::Mcp::TimeoutError
      ToolExecutionError = Captain::Mcp::ToolExecutionError
    end
  end
end
