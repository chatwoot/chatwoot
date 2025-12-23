# frozen_string_literal: true

#
# This code is based on https://github.com/standardrb/standard.
#
# Copyright (c) 2023 Test Double, Inc.
#
# The MIT License (MIT)
#
# https://github.com/standardrb/standard/blob/main/LICENSE.txt
#
module RuboCop
  module LSP
    # Log for Language Server Protocol of RuboCop.
    # @api private
    class Logger
      def self.log(message, prefix: '[server]')
        warn("#{prefix} #{message}")
      end
    end
  end
end
