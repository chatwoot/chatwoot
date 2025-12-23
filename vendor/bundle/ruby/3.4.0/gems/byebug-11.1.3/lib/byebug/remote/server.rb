# frozen_string_literal: true

require "socket"

module Byebug
  module Remote
    #
    # Server for remote debugging
    #
    class Server
      attr_reader :actual_port, :wait_connection

      def initialize(wait_connection:, &block)
        @thread = nil
        @wait_connection = wait_connection
        @main_loop = block
      end

      #
      # Start the remote debugging server
      #
      def start(host, port)
        return if @thread

        if wait_connection
          mutex = Mutex.new
          proceed = ConditionVariable.new
        end

        server = TCPServer.new(host, port)
        @actual_port = server.addr[1]

        yield if block_given?

        @thread = DebugThread.new do
          while (session = server.accept)
            @main_loop.call(session)

            mutex.synchronize { proceed.signal } if wait_connection
          end
        end

        mutex.synchronize { proceed.wait(mutex) } if wait_connection
      end
    end
  end
end
