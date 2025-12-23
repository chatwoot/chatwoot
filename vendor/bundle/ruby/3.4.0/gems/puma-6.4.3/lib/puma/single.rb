# frozen_string_literal: true

require_relative 'runner'
require_relative 'detect'
require_relative 'plugin'

module Puma
  # This class is instantiated by the `Puma::Launcher` and used
  # to boot and serve a Ruby application when no puma "workers" are needed
  # i.e. only using "threaded" mode. For example `$ puma -t 1:5`
  #
  # At the core of this class is running an instance of `Puma::Server` which
  # gets created via the `start_server` method from the `Puma::Runner` class
  # that this inherits from.
  class Single < Runner
    # @!attribute [r] stats
    def stats
      {
        started_at: utc_iso8601(@started_at)
      }.merge(@server.stats).merge(super)
    end

    def restart
      @server&.begin_restart
    end

    def stop
      @server&.stop false
    end

    def halt
      @server&.halt
    end

    def stop_blocked
      log "- Gracefully stopping, waiting for requests to finish"
      @control&.stop true
      @server&.stop true
    end

    def run
      output_header "single"

      load_and_bind

      Plugins.fire_background

      @launcher.write_state

      start_control

      @server = server = start_server
      server_thread = server.run

      log "Use Ctrl-C to stop"
      redirect_io

      @events.fire_on_booted!

      debug_loaded_extensions("Loaded Extensions:") if @log_writer.debug?

      begin
        server_thread.join
      rescue Interrupt
        # Swallow it
      end
    end
  end
end
