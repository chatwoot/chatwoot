# frozen_string_literal: true

module SidekiqAlive
  module Server
    module Base
      SHUTDOWN_SIGNAL = "TERM"
      QUIET_SIGNAL = "TSTP"

      # set web server to quiet mode
      def quiet!
        logger.info("[SidekiqAlive] Setting web server to quiet mode")
        Process.kill(QUIET_SIGNAL, @server_pid) unless @server_pid.nil?
      end

      private

      def configure_shutdown
        Kernel.at_exit do
          next if @server_pid.nil?

          logger.info("Shutting down SidekiqAlive web server")
          Process.kill(SHUTDOWN_SIGNAL, @server_pid)
          Process.wait(@server_pid)
        end
      end

      def configure_shutdown_signal(&block)
        Signal.trap(SHUTDOWN_SIGNAL, &block)
      end

      def configure_quiet_signal(&block)
        Signal.trap(QUIET_SIGNAL, &block)
      end

      def host
        SidekiqAlive.config.host
      end

      def port
        SidekiqAlive.config.port.to_i
      end

      def path
        SidekiqAlive.config.path
      end

      def logger
        SidekiqAlive.logger
      end
    end
  end
end
