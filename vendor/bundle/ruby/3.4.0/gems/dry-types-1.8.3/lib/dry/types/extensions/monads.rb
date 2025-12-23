# frozen_string_literal: true

require "dry/monads"
require "dry/monads/version"

if Gem::Version.new(Dry::Monads::VERSION) < Gem::Version.new("1.5.0")
  raise "dry-types requires dry-monads >= 1.5.0"
end

module Dry
  module Types
    # Monad extension for Result
    #
    # @api public
    class Result
      include ::Dry::Monads[:result]

      # Turn result into a monad
      #
      # This makes result objects work with dry-monads (or anything with a compatible interface)
      #
      # @return [Dry::Monads::Success,Dry::Monads::Failure]
      #
      # @api public
      def to_monad
        if success?
          Success(input)
        else
          Failure([error, input])
        end
      end
    end
  end
end
