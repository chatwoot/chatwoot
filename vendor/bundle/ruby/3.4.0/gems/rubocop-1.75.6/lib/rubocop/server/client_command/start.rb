# frozen_string_literal: true

#
# This code is based on https://github.com/fohte/rubocop-daemon.
#
# Copyright (c) 2018 Hayato Kawai
#
# The MIT License (MIT)
#
# https://github.com/fohte/rubocop-daemon/blob/master/LICENSE.txt
#
module RuboCop
  module Server
    module ClientCommand
      # This class is a client command to start server process.
      # @api private
      class Start < Base
        def initialize(detach: true)
          @detach = detach
          super()
        end

        def run
          if Server.running?
            warn "RuboCop server (#{Cache.pid_path.read}) is already running."
            return
          end

          Cache.acquire_lock do |locked|
            unless locked
              # Another process is already starting server,
              # so wait for it to be ready.
              Server.wait_for_running_status!(true)
              exit 0
            end

            Cache.write_version_file(Cache.restart_key)

            host = ENV.fetch('RUBOCOP_SERVER_HOST', '127.0.0.1')
            port = ENV.fetch('RUBOCOP_SERVER_PORT', 0)

            Server::Core.new.start(host, port, detach: @detach)
          end
        end
      end
    end
  end
end
