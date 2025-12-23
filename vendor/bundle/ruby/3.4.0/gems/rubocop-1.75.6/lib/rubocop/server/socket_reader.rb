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
    # This class sends the request read from the socket to server.
    # @api private
    class SocketReader
      Request = Struct.new(:header, :body)
      Header = Struct.new(:token, :cwd, :command, :args)

      def initialize(socket)
        @socket = socket
      end

      def read!
        request = parse_request(@socket.read)

        stderr = StringIO.new
        Helper.redirect(
          stdin: StringIO.new(request.body),
          stdout: @socket,
          stderr: stderr
        ) do
          create_command_instance(request).run
        end
      ensure
        Cache.stderr_path.write(stderr.string)
        @socket.close
      end

      private

      def parse_request(content)
        raw_header, *body = content.lines

        Request.new(parse_header(raw_header), body.join)
      end

      def parse_header(header)
        token, cwd, command, *args = header.shellsplit
        Header.new(token, cwd, command, args)
      end

      def create_command_instance(request)
        klass = find_command_class(request.header.command)

        klass.new(request.header.args, token: request.header.token, cwd: request.header.cwd)
      end

      def find_command_class(command)
        case command
        when 'stop' then ServerCommand::Stop
        when 'exec' then ServerCommand::Exec
        else
          raise UnknownServerCommandError, "#{command.inspect} is not a valid command"
        end
      end
    end
  end
end
