# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks whether `expect_offense` and correction expectation methods
      # (i.e. `expect_correction` and `expect_no_corrections`) are separated by empty line.
      #
      # @example
      #   # bad
      #   it 'registers and corrects an offense' do
      #     expect_offense(<<~RUBY)
      #       bad_method
      #       ^^^^^^^^^^ Use `good_method`.
      #     RUBY
      #     expect_correction(<<~RUBY)
      #       good_method
      #     RUBY
      #   end
      #
      #   # good
      #   it 'registers and corrects an offense' do
      #     expect_offense(<<~RUBY)
      #       bad_method
      #       ^^^^^^^^^^ Use `good_method`.
      #     RUBY
      #
      #     expect_correction(<<~RUBY)
      #       good_method
      #     RUBY
      #   end
      #
      class EmptyLineBetweenExpectOffenseAndCorrection < Base
        extend AutoCorrector

        MSG = 'Add empty line between `expect_offense` and `%<expect_correction>s`.'
        RESTRICT_ON_SEND = %i[expect_offense].freeze
        CORRECTION_EXPECTATION_METHODS = %i[expect_correction expect_no_corrections].freeze

        def on_send(node)
          return unless (next_sibling = node.right_sibling)
          return unless next_sibling.respond_to?(:send_type?) && next_sibling.send_type?

          method_name = next_sibling.method_name
          return unless CORRECTION_EXPECTATION_METHODS.include?(method_name)

          range = offense_range(node)
          return unless range.last_line + 1 == next_sibling.loc.line

          add_offense(range, message: format(MSG, expect_correction: method_name)) do |corrector|
            corrector.insert_after(range, "\n")
          end
        end

        private

        def offense_range(node)
          first_argument = node.first_argument

          if first_argument.respond_to?(:heredoc?) && first_argument.heredoc?
            first_argument.loc.heredoc_end
          else
            node
          end
        end
      end
    end
  end
end
