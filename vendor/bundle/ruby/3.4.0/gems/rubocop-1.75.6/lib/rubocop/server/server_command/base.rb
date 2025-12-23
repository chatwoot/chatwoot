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
      # Abstract base class for server command.
      # @api private
      class Base
        # Common functionality for working with subclasses of this class.
        # @api private
        module Runner
          def run
            validate_token!
            Dir.chdir(@cwd) do
              super
            end
          end
        end

        def self.inherited(child)
          super
          child.prepend Runner
        end

        def initialize(args, token: '', cwd: Dir.pwd)
          @args = args
          @token = token
          @cwd = cwd
        end

        def run; end

        private

        def validate_token!
          raise InvalidTokenError unless Cache.token_path.read == @token
        end
      end
    end
  end
end
