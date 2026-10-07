# The MCP server turns an exception inside a tool into a JSON-RPC error, so report it here or it is lost.
MCP.configure do |config|
  config.exception_reporter = lambda do |exception, _context|
    ChatwootExceptionTracker.new(exception, account: Current.account, user: Current.user).capture_exception
  end
end
