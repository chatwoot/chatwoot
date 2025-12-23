# frozen_string_literal: true

module WebMock
  module Matchers
    # this is a based on RSpec::Mocks::ArgumentMatchers::AnyArgMatcher
    class AnyArgMatcher
      def initialize(ignore)
      end

      def ==(other)
        true
      end
    end
  end
end
