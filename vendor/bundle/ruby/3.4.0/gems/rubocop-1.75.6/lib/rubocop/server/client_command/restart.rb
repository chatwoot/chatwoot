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
      # This class is a client command to restart server process.
      # @api private
      class Restart < Base
        def run
          ClientCommand::Stop.new.run
          ClientCommand::Start.new.run
        end
      end
    end
  end
end
