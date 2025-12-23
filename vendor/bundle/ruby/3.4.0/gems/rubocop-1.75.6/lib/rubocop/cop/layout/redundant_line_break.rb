# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether certain expressions, e.g. method calls, that could fit
      # completely on a single line, are broken up into multiple lines unnecessarily.
      #
      # @example
      #   # bad
      #   foo(
      #     a,
      #     b
      #   )
      #
      #   # good
      #   foo(a, b)
      #
      #   # bad
      #   puts 'string that fits on ' \
      #        'a single line'
      #
      #   # good
      #   puts 'string that fits on a single line'
      #
      #   # bad
      #   things
      #     .select { |thing| thing.cond? }
      #     .join('-')
      #
      #   # good
      #   things.select { |thing| thing.cond? }.join('-')
      #
      # @example InspectBlocks: false (default)
      #   # good
      #   foo(a) do |x|
      #     puts x
      #   end
      #
      # @example InspectBlocks: true
      #   # bad
      #   foo(a) do |x|
      #     puts x
      #   end
      #
      #   # good
      #   foo(a) { |x| puts x }
      #
      class RedundantLineBreak < Base
        include CheckAssignment
        include CheckSingleLineSuitability
        extend AutoCorrector

        MSG = 'Redundant line break detected.'

        def on_lvasgn(node)
          super unless end_with_percent_blank_string?(processed_source)
        end

        def on_send(node)
          # Include "the whole expression".
          node = node.parent while node.parent&.send_type? ||
                                   convertible_block?(node) ||
                                   node.parent.is_a?(RuboCop::AST::BinaryOperatorNode)

          return unless offense?(node) && !part_of_ignored_node?(node)

          register_offense(node)
        end
        alias on_csend on_send

        private

        def end_with_percent_blank_string?(processed_source)
          processed_source.buffer.source.end_with?("%\n\n")
        end

        def check_assignment(node, _rhs)
          return unless offense?(node)

          register_offense(node)
        end

        def register_offense(node)
          add_offense(node) do |corrector|
            corrector.replace(node, to_single_line(node.source).strip)
          end
          ignore_node(node)
        end

        def offense?(node)
          return false unless node.multiline? && suitable_as_single_line?(node)
          return require_backslash?(node) if node.operator_keyword?

          !index_access_call_chained?(node) && !configured_to_not_be_inspected?(node)
        end

        def require_backslash?(node)
          processed_source.lines[node.loc.operator.line - 1].end_with?('\\')
        end

        def index_access_call_chained?(node)
          return false unless node.send_type? && node.method?(:[])

          node.children.first.send_type? && node.children.first.method?(:[])
        end

        def configured_to_not_be_inspected?(node)
          return true if other_cop_takes_precedence?(node)
          return false if cop_config['InspectBlocks']

          node.any_block_type? || any_descendant?(node, :any_block, &:multiline?)
        end

        def other_cop_takes_precedence?(node)
          single_line_block_chain_enabled? && any_descendant?(node, :any_block) do |block_node|
            block_node.parent.send_type? && block_node.parent.loc.dot && !block_node.multiline?
          end
        end

        def single_line_block_chain_enabled?
          @config.cop_enabled?('Layout/SingleLineBlockChain')
        end

        def convertible_block?(node)
          return false unless (parent = node.parent)

          parent.any_block_type? && node == parent.send_node &&
            (node.parenthesized? || !node.arguments?)
        end
      end
    end
  end
end
