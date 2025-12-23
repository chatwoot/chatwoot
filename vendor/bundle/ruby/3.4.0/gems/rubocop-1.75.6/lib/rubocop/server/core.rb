# frozen_string_literal: true

require 'securerandom'
require 'socket'
require 'stringio'

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
    # The core of server process. It starts TCP server and perform socket communication.
    # @api private
    class Core
      JSON_FORMATS = %w[json j].freeze

      def self.token
        @token ||= SecureRandom.hex(4)
      end

      def token
        self.class.token
      end

      def start(host, port, detach: true)
        $PROGRAM_NAME = "rubocop --server #{Cache.project_dir}"

        require_relative '../../rubocop'
        start_server(host, port)

        return unless server_mode?

        detach ? detach_server : run_server
      end

      private

      def detach_server
        write_port_and_token_files

        pid = fork do
          if defined?(RubyVM::YJIT.enable)
            RubyVM::YJIT.enable
          end

          Process.daemon(true)
          $stderr.reopen(Cache.stderr_path, 'w')
          process_input
        end

        Process.waitpid(pid)
      end

      def write_port_and_token_files
        Cache.write_port_and_token_files(port: @server.addr[1], token: token)
      end

      def process_input
        Cache.write_pid_file do
          read_socket(@server.accept) until @server.closed?
        end
      end

      def run_server
        write_port_and_token_files
        process_input
      end

      def server_mode?
        true
      end

      def start_server(host, port)
        @server = TCPServer.open(host, port)

        # JSON format does not expected output message when IDE integration with server mode.
        # See: https://github.com/rubocop/rubocop/issues/11164
        return if use_json_format?

        output_stream = ARGV.include?('--stderr') ? $stderr : $stdout
        output_stream.puts "RuboCop server starting on #{@server.addr[3]}:#{@server.addr[1]}."
      end

      def read_socket(socket)
        SocketReader.new(socket).read!
      rescue InvalidTokenError
        socket.puts 'token is not valid.'
      rescue ServerStopRequest
        @server.close
      rescue UnknownServerCommandError => e
        socket.puts e.message
      rescue Errno::EPIPE => e
        warn e.inspect
      rescue StandardError => e
        socket.puts e.full_message
      ensure
        socket.close
      end

      def use_json_format?
        return true if ARGV.include?('--format=json') || ARGV.include?('--format=j')
        return false unless (index = ARGV.index('--format') || ARGV.index('-f'))

        format = ARGV[index + 1]

        JSON_FORMATS.include?(format)
      end
    end
  end
end
