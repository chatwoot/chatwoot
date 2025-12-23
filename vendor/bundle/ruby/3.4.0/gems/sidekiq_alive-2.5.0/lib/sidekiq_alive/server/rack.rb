# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Server
    class Rack
      extend Base

      class << self
        def run!
          logger.info("[SidekiqAlive] Starting healthcheck '#{server}' server")
          @server_pid = ::Process.fork do
            @handler = handler
            configure_shutdown_signal { @handler.shutdown }
            configure_quiet_signal { @quiet = Time.now }

            @handler.run(self, Port: port, Host: host, AccessLog: [], Logger: logger)
          end
          configure_shutdown

          self
        end

        def call(env)
          req = ::Rack::Request.new(env)

          if req.path != path
            logger.warn("[SidekiqAlive] Path '#{req.path}' not found")
            return [404, {}, ["Not found"]]
          end

          if quiet?
            logger.debug("[SidekiqAlive] [SidekiqAlive] Server in quiet mode, skipping alive key lookup!")
            return [200, {}, ["Server is shutting down"]]
          end

          if SidekiqAlive.alive?
            logger.debug("[SidekiqAlive] Found alive key!")
            return [200, {}, ["Alive!"]]
          end

          response = "Can't find the alive key"
          logger.error("[SidekiqAlive] #{response}")
          [404, {}, [response]]
        rescue StandardError => e
          logger.error("[SidekiqAlive] #{response} looking for alive key. Error: #{e.message}")
          [500, {}, ["Internal Server Error"]]
        end

        private

        def quiet?
          @quiet && (Time.now - @quiet) < SidekiqAlive.config.quiet_timeout
        end

        def handler
          Helpers.use_rackup? ? ::Rackup::Handler.get(server) : ::Rack::Handler.get(server)
        end

        def server
          SidekiqAlive.config.server
        end
      end
    end
  end
end
