# frozen_string_literal: true

require "socket"
require_relative "processors/control_processor"
require_relative "remote/server"
require_relative "remote/client"

#
# Remote debugging functionality.
#
module Byebug
  # Port number used for remote debugging
  PORT = 8989 unless defined?(PORT)

  class << self
    # If in remote mode, wait for the remote connection
    attr_accessor :wait_connection

    # The actual port that the server is started at
    def actual_port
      server.actual_port
    end

    # The actual port that the control server is started at
    def actual_control_port
      control.actual_port
    end

    #
    # Interrupts the current thread
    #
    def interrupt
      current_context.interrupt
    end

    #
    # Starts the remote server main thread
    #
    def start_server(host = nil, port = PORT)
      start_control(host, port.zero? ? 0 : port + 1)

      server.start(host, port)
    end

    #
    # Starts the remote server control thread
    #
    def start_control(host = nil, port = PORT + 1)
      control.start(host, port)
    end

    #
    # Connects to the remote byebug
    #
    def start_client(host = "localhost", port = PORT)
      client.start(host, port)
    end

    def parse_host_and_port(host_port_spec)
      location = host_port_spec.split(":")
      location[1] ? [location[0], location[1].to_i] : ["localhost", location[0]]
    end

    private

    def client
      @client ||= Remote::Client.new(Context.interface)
    end

    def server
      @server ||= Remote::Server.new(wait_connection: wait_connection) do |s|
        Context.interface = RemoteInterface.new(s)
      end
    end

    def control
      @control ||= Remote::Server.new(wait_connection: false) do |s|
        context = Byebug.current_context
        interface = RemoteInterface.new(s)

        ControlProcessor.new(context, interface).process_commands
      end
    end
  end
end
