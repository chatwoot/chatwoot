# We intentionally do not use the `RSpec::Support.require...` methods
# here so that this file can be loaded individually, as documented
# below.
require 'rspec/mocks/argument_matchers'
require 'rspec/support/fuzzy_matcher'

module RSpec
  module Mocks
    # Wrapper for matching arguments against a list of expected values. Used by
    # the `with` method on a `MessageExpectation`:
    #
    #     expect(object).to receive(:message).with(:a, 'b', 3)
    #     object.message(:a, 'b', 3)
    #
    # Values passed to `with` can be literal values or argument matchers that
    # match against the real objects .e.g.
    #
    #     expect(object).to receive(:message).with(hash_including(:a => 'b'))
    #
    # Can also be used directly to match the contents of any `Array`. This
    # enables 3rd party mocking libs to take advantage of rspec's argument
    # matching without using the rest of rspec-mocks.
    #
    #     require 'rspec/mocks/argument_list_matcher'
    #     include RSpec::Mocks::ArgumentMatchers
    #
    #     arg_list_matcher = RSpec::Mocks::ArgumentListMatcher.new(123, hash_including(:a => 'b'))
    #     arg_list_matcher.args_match?(123, :a => 'b')
    #
    # This class is immutable.
    #
    # @see ArgumentMatchers
    class ArgumentListMatcher
      # @private
      attr_reader :expected_args

      # @api public
      # @param [Array] expected_args a list of expected literals and/or argument matchers
      #
      # Initializes an `ArgumentListMatcher` with a collection of literal
      # values and/or argument matchers.
      #
      # @see ArgumentMatchers
      # @see #args_match?
      def initialize(*expected_args)
        @expected_args = expected_args
        ensure_expected_args_valid!
      end
      ruby2_keywords :initialize if respond_to?(:ruby2_keywords, true)

      # @api public
      # @param [Array] actual_args
      #
      # Matches each element in the `expected_args` against the element in the same
      # position of the arguments passed to `new`.
      #
      # @see #initialize
      def args_match?(*actual_args)
        expected_args = resolve_expected_args_based_on(actual_args)

        return false if expected_args.size != actual_args.size

        if RUBY_VERSION >= "3"
          # If the expectation was set with keywords, while the actual method was called with a positional hash argument, they don't match.
          # If the expectation was set without keywords, e.g., with({a: 1}), then it fine to call it with either foo(a: 1) or foo({a: 1}).
          # This corresponds to Ruby semantics, as if the method was def foo(options).
          if Hash === expected_args.last && Hash === actual_args.last
            if !Hash.ruby2_keywords_hash?(actual_args.last) && Hash.ruby2_keywords_hash?(expected_args.last)
              return false
            end
          end
        end

        Support::FuzzyMatcher.values_match?(expected_args, actual_args)
      end
      ruby2_keywords :args_match? if respond_to?(:ruby2_keywords, true)

      # @private
      # Resolves abstract arg placeholders like `no_args` and `any_args` into
      # a more concrete arg list based on the provided `actual_args`.
      def resolve_expected_args_based_on(actual_args)
        return [] if [ArgumentMatchers::NoArgsMatcher::INSTANCE] == expected_args

        any_args_index = expected_args.index { |a| ArgumentMatchers::AnyArgsMatcher::INSTANCE == a }
        return expected_args unless any_args_index

        replace_any_args_with_splat_of_anything(any_args_index, actual_args.count)
      end

    private

      def replace_any_args_with_splat_of_anything(before_count, actual_args_count)
        any_args_count  = actual_args_count   - expected_args.count + 1
        after_count     = expected_args.count - before_count        - 1

        any_args = 1.upto(any_args_count).map { ArgumentMatchers::AnyArgMatcher::INSTANCE }
        expected_args.first(before_count) + any_args + expected_args.last(after_count)
      end

      def ensure_expected_args_valid!
        if expected_args.count { |a| ArgumentMatchers::AnyArgsMatcher::INSTANCE == a } > 1
          raise ArgumentError, "`any_args` can only be passed to " \
                "`with` once but you have passed it multiple times."
        elsif expected_args.count > 1 && expected_args.any? { |a| ArgumentMatchers::NoArgsMatcher::INSTANCE == a }
          raise ArgumentError, "`no_args` can only be passed as a " \
                "singleton argument to `with` (i.e. `with(no_args)`), " \
                "but you have passed additional arguments."
        end
      end

      # Value that will match all argument lists.
      #
      # @private
      MATCH_ALL = new(ArgumentMatchers::AnyArgsMatcher::INSTANCE)
    end
  end
end
