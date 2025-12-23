# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant `return` expressions.
      #
      # @example
      #   # These bad cases should be extended to handle methods whose body is
      #   # if/else or a case expression with a default branch.
      #
      #   # bad
      #   def test
      #     return something
      #   end
      #
      #   # bad
      #   def test
      #     one
      #     two
      #     three
      #     return something
      #   end
      #
      #   # bad
      #   def test
      #     return something if something_else
      #   end
      #
      #   # good
      #   def test
      #     something if something_else
      #   end
      #
      #   # good
      #   def test
      #     if x
      #     elsif y
      #     else
      #     end
      #   end
      #
      # @example AllowMultipleReturnValues: false (default)
      #   # bad
      #   def test
      #     return x, y
      #   end
      #
      # @example AllowMultipleReturnValues: true
      #   # good
      #   def test
      #     return x, y
      #   end
      #
      class RedundantReturn < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant `return` detected.'
        MULTI_RETURN_MSG = 'To return multiple values, use an array.'
        RESTRICT_ON_SEND = %i[define_method define_singleton_method lambda].freeze

        def on_send(node)
          return unless node.block_literal?

          check_branch(node.parent.body)
        end

        def on_def(node)
          check_branch(node.body)
        end
        alias on_defs on_def

        private

        def correct_without_arguments(return_node, corrector)
          corrector.replace(return_node, 'nil')
        end

        def correct_with_arguments(return_node, corrector)
          if return_node.children.size > 1
            add_brackets(corrector, return_node)
          elsif hash_without_braces?(return_node.first_argument)
            add_braces(corrector, return_node.first_argument)
          end
          if return_node.splat_argument?
            first_argument = return_node.first_argument
            corrector.replace(first_argument, first_argument.source.delete_prefix('*'))
          end

          keyword = range_with_surrounding_space(return_node.loc.keyword, side: :right)
          corrector.remove(keyword)
        end

        def hash_without_braces?(node)
          node.hash_type? && !node.braces?
        end

        def add_brackets(corrector, node)
          corrector.insert_before(node.children.first, '[')
          corrector.insert_after(node.children.last, ']')
        end

        def add_braces(corrector, node)
          corrector.insert_before(node.children.first, '{')
          corrector.insert_after(node.children.last, '}')
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def check_branch(node)
          return unless node

          case node.type
          when :return then check_return_node(node)
          when :case   then check_case_node(node)
          when :case_match then check_case_match_node(node)
          when :if     then check_if_node(node)
          when :rescue then check_rescue_node(node)
          when :resbody then check_resbody_node(node)
          when :ensure then check_ensure_node(node)
          when :begin, :kwbegin
            check_begin_node(node)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def check_return_node(node)
          return if cop_config['AllowMultipleReturnValues'] && node.children.size > 1

          add_offense(node.loc.keyword, message: message(node)) do |corrector|
            if node.arguments?
              correct_with_arguments(node, corrector)
            else
              correct_without_arguments(node, corrector)
            end
          end
        end

        def check_case_node(node)
          node.when_branches.each { |when_node| check_branch(when_node.body) }
          check_branch(node.else_branch)
        end

        def check_case_match_node(node)
          node.in_pattern_branches.each { |in_pattern_node| check_branch(in_pattern_node.body) }
          check_branch(node.else_branch)
        end

        def check_if_node(node)
          return if node.ternary?

          check_branch(node.if_branch)
          check_branch(node.else_branch)
        end

        def check_rescue_node(node)
          node.branches.each { |branch| check_branch(branch) }
          check_branch(node.body) unless node.else?
        end

        def check_resbody_node(node)
          check_branch(node.body)
        end

        def check_ensure_node(node)
          rescue_node = node.node_parts[0]
          check_branch(rescue_node)
        end

        def check_begin_node(node)
          last_expr = node.children.last
          check_branch(last_expr)
        end

        def allow_multiple_return_values?
          cop_config['AllowMultipleReturnValues'] || false
        end

        def message(node)
          if !allow_multiple_return_values? && node.children.size > 1
            "#{MSG} #{MULTI_RETURN_MSG}"
          else
            MSG
          end
        end
      end
    end
  end
end
