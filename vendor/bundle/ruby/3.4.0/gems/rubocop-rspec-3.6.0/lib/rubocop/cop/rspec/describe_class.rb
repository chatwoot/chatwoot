# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that the first argument to the top-level describe is a constant.
      #
      # It can be configured to ignore strings when certain metadata is passed.
      #
      # Ignores Rails and Aruba `type` metadata by default.
      #
      # @example `IgnoredMetadata` configuration
      #   # .rubocop.yml
      #   # RSpec/DescribeClass:
      #   #   IgnoredMetadata:
      #   #     type:
      #   #       - request
      #   #       - controller
      #
      # @example
      #   # bad
      #   describe 'Do something' do
      #   end
      #
      #   # good
      #   describe TestedClass do
      #     subject { described_class }
      #   end
      #
      #   describe 'TestedClass::VERSION' do
      #     subject { Object.const_get(self.class.description) }
      #   end
      #
      #   describe "A feature example", type: :feature do
      #   end
      #
      class DescribeClass < Base
        include TopLevelGroup

        MSG = 'The first argument to describe should be ' \
              'the class or module being tested.'

        # @!method example_group_with_ignored_metadata?(node)
        def_node_matcher :example_group_with_ignored_metadata?, <<~PATTERN
          (send #rspec? :describe ... (hash <#ignored_metadata? ...>))
        PATTERN

        # @!method not_a_const_described(node)
        def_node_matcher :not_a_const_described, <<~PATTERN
          (send #rspec? :describe $[!const !#string_constant?] ...)
        PATTERN

        # @!method sym_pair(node)
        def_node_matcher :sym_pair, <<~PATTERN
          (pair $sym $sym)
        PATTERN

        def on_top_level_group(node)
          return if example_group_with_ignored_metadata?(node.send_node)

          not_a_const_described(node.send_node) do |described|
            add_offense(described)
          end
        end

        private

        def ignored_metadata?(node)
          sym_pair(node) do |key, value|
            ignored_metadata[key.value.to_s].to_a.include?(value.value.to_s)
          end
        end

        def string_constant?(described)
          described.str_type? &&
            described.value.match?(/^(?:(?:::)?[A-Z]\w*)+$/)
        end

        def ignored_metadata
          cop_config['IgnoredMetadata'] || {}
        end
      end
    end
  end
end
