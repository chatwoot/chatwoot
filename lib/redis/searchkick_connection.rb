module Redis::SearchkickConnection
  def self.with
    # Searchkick uses raw commands and owns its key prefixes; bypass Alfred's namespace,
    # while keeping the connection checked out from the shared pool for the whole block.
    Redis::Alfred.with { |connection| yield connection.redis }
  end
end
