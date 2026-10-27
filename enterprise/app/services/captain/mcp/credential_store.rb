# The RubyLLM credential store for one MCP server. RubyLLM keeps OAuth sign-in state, tokens and client
# registrations here, in the server's oauth_credentials, which is encrypted like other secrets.
# The store loads its own copy of the server row, so it never locks or writes the caller's record, which may hold an
# admin edit that is not saved yet.
class Captain::Mcp::CredentialStore
  def initialize(server)
    @server_id = server.id
  end

  def read(key)
    record.oauth_credentials[key]
  end

  def write(key, data, owner: nil) # rubocop:disable Lint/UnusedMethodArgument
    save(record.oauth_credentials.merge(key => data))
  end

  def delete(key)
    save(record.oauth_credentials.except(key))
  end

  # Locks the server row, so only one process refreshes the tokens. The lock reloads the stored credentials first.
  def synchronize(_key, &)
    record.with_lock(&)
  end

  private

  def record
    @record ||= Captain::McpServer.find(@server_id)
  end

  # RubyLLM writes here during the OAuth callback and when it refreshes a token in an agent run. update_columns writes
  # only oauth_credentials, so a validation on another column, such as the stored tools, cannot drop a token the
  # authorization server already issued.
  def save(credentials)
    record.update_columns(oauth_credentials: credentials) # rubocop:disable Rails/SkipsModelValidations
  end
end
