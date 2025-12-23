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
    # @api private
    module ServerCommand
      autoload :Base, 'rubocop/server/server_command/base'
      autoload :Exec, 'rubocop/server/server_command/exec'
      autoload :Stop, 'rubocop/server/server_command/stop'
    end
  end
end
