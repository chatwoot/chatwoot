# frozen_string_literal: true

module WebMock
  module Matchers
    # this is a based on RSpec::Mocks::ArgumentMatchers::HashIncludingMatcher
    # https://github.com/rspec/rspec-mocks/blob/master/lib/rspec/mocks/argument_matchers.rb
    class HashIncludingMatcher < HashArgumentMatcher
      def ==(actual)
        super { |key, value| actual.key?(key) && value === actual[key] }
      rescue NoMethodError
        false
      end

      def inspect
        "hash_including(#{@expected.inspect})"
      end
    end
  end
end
