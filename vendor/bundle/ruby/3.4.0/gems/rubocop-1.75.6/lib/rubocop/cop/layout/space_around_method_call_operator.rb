# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks method call operators to not have spaces around them.
      #
      # @example
      #   # bad
      #   foo. bar
      #   foo .bar
      #   foo . bar
      #   foo. bar .buzz
      #   foo
      #     . bar
      #     . buzz
      #   foo&. bar
      #   foo &.bar
      #   foo &. bar
      #   foo &. bar&. buzz
      #   RuboCop:: Cop
      #   RuboCop:: Cop:: Base
      #   :: RuboCop::Cop
      #
      #   # good
      #   foo.bar
      #   foo.bar.buzz
      #   foo
      #     .bar
      #     .buzz
      #   foo&.bar
      #   foo&.bar&.buzz
      #   RuboCop::Cop
      #   RuboCop::Cop::Base
      #   ::RuboCop::Cop
      #
      class SpaceAroundMethodCallOperator < Base
        include RangeHelp
        extend AutoCorrector

        SPACES_REGEXP = /\A[ \t]+\z/.freeze

        MSG = 'Avoid using spaces around a method call operator.'

        def on_send(node)
          return unless node.dot? || node.safe_navigation?

          check_space_before_dot(node)
          check_space_after_dot(node)
        end
        alias on_csend on_send

        def on_const(node)
          return unless node.loc?(:double_colon)

          check_space_after_double_colon(node)
        end

        private

        def check_space_before_dot(node)
          receiver_pos = node.receiver.source_range.end_pos
          dot_pos = node.loc.dot.begin_pos
          check_space(receiver_pos, dot_pos)
        end

        def check_space_after_dot(node)
          dot_pos = node.loc.dot.end_pos

          selector_pos =
            # `Proc#call` shorthand syntax
            if node.method?(:call) && !node.loc.selector
              node.loc.begin.begin_pos
            else
              node.loc.selector.begin_pos
            end

          check_space(dot_pos, selector_pos)
        end

        def check_space_after_double_colon(node)
          double_colon_pos = node.loc.double_colon.end_pos
          name_pos = node.loc.name.begin_pos
          check_space(double_colon_pos, name_pos)
        end

        def check_space(begin_pos, end_pos)
          return if end_pos <= begin_pos

          range = range_between(begin_pos, end_pos)
          return unless range.source.match?(SPACES_REGEXP)

          add_offense(range) { |corrector| corrector.remove(range) }
        end
      end
    end
  end
end
