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
    module ServerCommand
      # This class is a server command to stop server process.
      # @api private
      class Stop < Base
        def run
          raise ServerStopRequest
        end
      end
    end
  end
end
