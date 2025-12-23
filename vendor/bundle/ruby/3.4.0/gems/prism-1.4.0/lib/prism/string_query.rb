# frozen_string_literal: true

module Prism
  # Query methods that allow categorizing strings based on their context for
  # where they could be valid in a Ruby syntax tree.
  class StringQuery
    # The string that this query is wrapping.
    attr_reader :string

    # Initialize a new query with the given string.
    def initialize(string)
      @string = string
    end

    # Whether or not this string is a valid local variable name.
    def local?
      StringQuery.local?(string)
    end

    # Whether or not this string is a valid constant name.
    def constant?
      StringQuery.constant?(string)
    end

    # Whether or not this string is a valid method name.
    def method_name?
      StringQuery.method_name?(string)
    end
  end
end
