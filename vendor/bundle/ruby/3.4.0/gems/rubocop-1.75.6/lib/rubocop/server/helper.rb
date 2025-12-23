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
    # This module has a helper method for `RuboCop::Server::SocketReader`.
    # @api private
    module Helper
      def self.redirect(stdin: $stdin, stdout: $stdout, stderr: $stderr, &_block)
        old_stdin = $stdin.dup
        old_stdout = $stdout.dup
        old_stderr = $stderr.dup

        $stdin = stdin
        $stdout = stdout
        $stderr = stderr

        yield
      ensure
        $stdin = old_stdin
        $stdout = old_stdout
        $stderr = old_stderr
      end
    end
  end
end
