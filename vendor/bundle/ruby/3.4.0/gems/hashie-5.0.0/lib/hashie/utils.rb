module Hashie
  # A collection of helper methods that can be used throughout the gem.
  module Utils
    # Describes a method by where it was defined.
    #
    # @param bound_method [Method] The method to describe.
    # @return [String]
    def self.method_information(bound_method)
      if bound_method.source_location
        "defined at #{bound_method.source_location.join(':')}"
      else
        "defined in #{bound_method.owner}"
      end
    end

    # Duplicates a value or returns the value when it is not duplicable
    #
    # @api public
    #
    # @param value [Object] the value to safely duplicate
    # @return [Object] the duplicated value
    def self.safe_dup(value)
      case value
      when Complex, FalseClass, NilClass, Rational, Method, Symbol, TrueClass, *integer_classes
        value
      else
        value.dup
      end
    end

    # Lists the classes Ruby uses for integers
    #
    # @api private
    # @return [Array<Class>]
    def self.integer_classes
      @integer_classes ||=
        if 0.class == Integer
          [Integer]
        else
          [Fixnum, Bignum] # rubocop:disable Lint/UnifiedInteger
        end
    end
  end
end
