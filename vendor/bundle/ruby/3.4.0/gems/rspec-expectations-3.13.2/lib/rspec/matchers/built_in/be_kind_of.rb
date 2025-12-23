module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `be_a_kind_of`.
      # Not intended to be instantiated directly.
      class BeAKindOf < BaseMatcher
      private

        def match(expected, actual)
          actual.kind_of?(expected)
        rescue NoMethodError
          raise ::ArgumentError, "The #{matcher_name} matcher requires that " \
                                 "the actual object responds to #kind_of? method " \
                                 "but a `NoMethodError` was encountered instead."
        end
      end
    end
  end
end
