# frozen_string_literal: true

module Igaralead
  # Abstract base for models backed by the shared igaralead DB.
  # Uses a separate connection pool (via establish_connection) so it
  # doesn't interfere with Chatwoot's primary database.
  #
  # Env: SHARED_DATABASE_URL (defaults to primary DB for dev convenience)
  class SharedRecord < ActiveRecord::Base
    self.abstract_class = true

    establish_connection(
      ENV.fetch('SHARED_DATABASE_URL', nil) || {
        adapter: 'postgresql',
        host: ENV.fetch('POSTGRES_HOST', 'localhost'),
        port: ENV.fetch('POSTGRES_PORT', 5432),
        database: ENV.fetch('SHARED_DATABASE_NAME', 'igaralead'),
        username: ENV.fetch('POSTGRES_USERNAME', 'postgres'),
        password: ENV.fetch('POSTGRES_PASSWORD', '')
      }
    )
  end
end
