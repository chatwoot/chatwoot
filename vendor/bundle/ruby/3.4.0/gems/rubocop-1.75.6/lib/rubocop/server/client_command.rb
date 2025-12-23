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
  autoload :Version, 'rubocop/version'

  module Server
    # @api private
    module ClientCommand
      autoload :Base, 'rubocop/server/client_command/base'
      autoload :Exec, 'rubocop/server/client_command/exec'
      autoload :Restart, 'rubocop/server/client_command/restart'
      autoload :Start, 'rubocop/server/client_command/start'
      autoload :Status, 'rubocop/server/client_command/status'
      autoload :Stop, 'rubocop/server/client_command/stop'
    end
  end
end
