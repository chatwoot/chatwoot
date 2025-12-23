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
      # This class is a client command to show server process status.
      # @api private
      class Status < Base
        def run
          if Server.running?
            puts "RuboCop server (#{Cache.pid_path.read}) is running."
          else
            puts 'RuboCop server is not running.'
          end
        end
      end
    end
  end
end
