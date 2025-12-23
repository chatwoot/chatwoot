# frozen_string_literal: true

require 'shellwords'
require 'socket'

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
      # Abstract base class for server client command.
      # @api private
      class Base
        def run
          raise NotImplementedError
        end

        private

        def send_request(command:, args: [], body: '')
          TCPSocket.open('127.0.0.1', Cache.port_path.read) do |socket|
            socket.puts [Cache.token_path.read, Dir.pwd, command, *args].shelljoin
            socket.write body
            socket.close_write
            $stdout.write socket.readpartial(4096) until socket.eof?
          end
        end

        def check_running_server
          Server.running?.tap do |running|
            warn 'RuboCop server is not running.' unless running
          end
        end
      end
    end
  end
end
