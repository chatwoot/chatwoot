# The RubyLLM credential store for one MCP server. RubyLLM keeps OAuth sign-in state, tokens and client
# registrations here, and they live in the server's auth_config, which is encrypted like other secrets.
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
    @server.auth_config.fetch('oauth', {})
  end

  # Only auth_config is written, so storing a token never overwrites an admin edit
  def save(oauth)
    @server.update_columns(auth_config: @server.auth_config.merge('oauth' => oauth)) # rubocop:disable Rails/SkipsModelValidations
  end
end
