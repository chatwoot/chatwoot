# The RubyLLM credential store for one MCP server. RubyLLM keeps OAuth sign-in state, tokens and client
# registrations here, in the server's oauth_credentials, which is encrypted like other secrets.
class Captain::Mcp::CredentialStore
  def initialize(server)
    @server = server
  end

  def read(key)
    credentials[key]
  end

  def write(key, data, owner: nil) # rubocop:disable Lint/UnusedMethodArgument
    save(credentials.merge(key => data))
  end

  def delete(key)
    save(credentials.except(key))
  end

  # Locks the server row, so only one process refreshes the tokens. The lock reloads the stored credentials first.
  def synchronize(_key, &)
    @server.with_lock(&)
  end

  private

  def credentials
    @server.oauth_credentials
  end

  # RubyLLM writes here during the OAuth callback and when it refreshes a token in an agent run. update_columns writes
  # only oauth_credentials: a save would also store any unsaved change on the server, and a validation on another
  # column, such as the token header, would drop a token the authorization server already issued.
  def save(credentials)
    @server.update_columns(oauth_credentials: credentials) # rubocop:disable Rails/SkipsModelValidations
  end
end
