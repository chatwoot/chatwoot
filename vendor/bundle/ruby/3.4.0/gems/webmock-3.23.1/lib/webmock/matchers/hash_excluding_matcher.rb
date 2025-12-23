# frozen_string_literal: true

module WebMock
  module Matchers
    # this is a based on RSpec::Mocks::ArgumentMatchers::HashExcludingMatcher
    # https://github.com/rspec/rspec-mocks/blob/master/lib/rspec/mocks/argument_matchers.rb
    class HashExcludingMatcher < HashArgumentMatcher
      def ==(actual)
        super { |key, value| !actual.key?(key) || value != actual[key] }
      end

      def inspect
        "hash_excluding(#{@expected.inspect})"
      end
    end
  end
end
