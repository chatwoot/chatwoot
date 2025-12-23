# frozen_string_literal: true

require "socket"

module Byebug
  module Remote
    #
    # Client for remote debugging
    #
    class Client
      attr_reader :interface, :socket

      def initialize(interface)
        @interface = interface
        @socket = nil
      end

      #
      # Connects to the remote byebug
      #
      def start(host = "localhost", port = PORT)
        connect_at(host, port)

        while (line = socket.gets)
          case line
          when /^PROMPT (.*)$/
            input = interface.read_command(Regexp.last_match[1])
            break unless input

            socket.puts input
          when /^CONFIRM (.*)$/
            input = interface.readline(Regexp.last_match[1])
            break unless input

            socket.puts input
          else
            interface.puts line
          end
        end

        socket.close
      end

      def started?
        !socket.nil?
      end

      private

      def connect_at(host, port)
        interface.puts "Connecting to byebug server at #{host}:#{port}..."
        @socket = TCPSocket.new(host, port)
        interface.puts "Connected."
      end
    end
  end
end
