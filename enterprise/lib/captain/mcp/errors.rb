module Captain
  module Mcp
    class Error < StandardError; end
    class ConnectionError < Error; end
    class ProtocolError < Error; end
    class AuthenticationError < Error; end
    class TimeoutError < Error; end
    class ToolExecutionError < Error; end
  end
end
