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
      # This class is a client command to stop server process.
      # @api private
      class Stop < Base
        def run
          return unless check_running_server

          pid = fork do
            send_request(command: 'stop')
            Server.wait_for_running_status!(false)
          end

          Process.waitpid(pid)
        end
      end
    end
  end
end
