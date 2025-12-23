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
    class InvalidTokenError < StandardError; end

    # @api private
    class ServerStopRequest < StandardError; end

    # @api private
    class UnknownServerCommandError < StandardError; end
  end
end
