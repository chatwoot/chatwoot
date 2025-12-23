# frozen_string_literal: true

module WebMock
  module Matchers
    # Base class for Hash matchers
    # https://github.com/rspec/rspec-mocks/blob/master/lib/rspec/mocks/argument_matchers.rb
    class HashArgumentMatcher
      def initialize(expected)
        @expected = Hash[WebMock::Util::HashKeysStringifier.stringify_keys!(expected, deep: true).sort]
      end

      def ==(_actual, &block)
        @expected.all?(&block)
      rescue NoMethodError
        false
      end

      def self.from_rspec_matcher(matcher)
        new(matcher.instance_variable_get(:@expected))
      end
    end
  end
end
