# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unneeded usages of splat expansion.
      #
      # @example
      #
      #   # bad
      #   a = *[1, 2, 3]
      #   a = *'a'
      #   a = *1
      #   ['a', 'b', *%w(c d e), 'f', 'g']
      #
      #   # good
      #   c = [1, 2, 3]
      #   a = *c
      #   a, b = *c
      #   a, *b = *c
      #   a = *1..10
      #   a = ['a']
      #   ['a', 'b', 'c', 'd', 'e', 'f', 'g']
      #
      #   # bad
      #   do_something(*['foo', 'bar', 'baz'])
      #
      #   # good
      #   do_something('foo', 'bar', 'baz')
      #
      #   # bad
      #   begin
      #     foo
      #   rescue *[StandardError, ApplicationError]
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue StandardError, ApplicationError
      #     bar
      #   end
      #
      #   # bad
      #   case foo
      #   when *[1, 2, 3]
      #     bar
      #   else
      #     baz
      #   end
      #
      #   # good
      #   case foo
      #   when 1, 2, 3
      #     bar
      #   else
      #     baz
      #   end
      #
      # @example AllowPercentLiteralArrayArgument: true (default)
      #
      #   # good
      #   do_something(*%w[foo bar baz])
      #
      # @example AllowPercentLiteralArrayArgument: false
      #
      #   # bad
      #   do_something(*%w[foo bar baz])
      #
      class RedundantSplatExpansion < Base
        extend AutoCorrector

        MSG = 'Replace splat expansion with comma separated values.'
        ARRAY_PARAM_MSG = 'Pass array contents as separate arguments.'
        PERCENT_W = '%w'
        PERCENT_CAPITAL_W = '%W'
        PERCENT_I = '%i'
        PERCENT_CAPITAL_I = '%I'
        ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn].freeze

        # @!method array_new?(node)
        def_node_matcher :array_new?, <<~PATTERN
          {
            $(send (const {nil? cbase} :Array) :new ...)
            $(block (send (const {nil? cbase} :Array) :new ...) ...)
          }
        PATTERN

        # @!method literal_expansion(node)
        def_node_matcher :literal_expansion, <<~PATTERN
          (splat {$({str dstr int float array} ...) (block $#array_new? ...) $#array_new?} ...)
        PATTERN

        def on_splat(node)
          redundant_splat_expansion(node) do
            if array_splat?(node) && (method_argument?(node) || part_of_an_array?(node))
              return if allow_percent_literal_array_argument? &&
                        use_percent_literal_array_argument?(node)

              add_offense(node, message: ARRAY_PARAM_MSG) do |corrector|
                autocorrect(corrector, node)
              end
            else
              add_offense(node) { |corrector| autocorrect(corrector, node) }
            end
          end
        end

        private

        def autocorrect(corrector, node)
          range, content = replacement_range_and_content(node)

          corrector.replace(range, content)
        end

        def redundant_splat_expansion(node)
          literal_expansion(node) do |expanded_item|
            if expanded_item.send_type?
              return if array_new_inside_array_literal?(expanded_item)

              grandparent = node.parent.parent
              return if grandparent && !ASSIGNMENT_TYPES.include?(grandparent.type)
            end

            yield
          end
        end

        def array_new_inside_array_literal?(array_new_node)
          return false unless array_new?(array_new_node)

          grandparent = array_new_node.parent.parent
          grandparent.array_type? && grandparent.children.size > 1
        end

        # rubocop:disable Metrics/AbcSize
        def replacement_range_and_content(node)
          variable = node.children.first
          expression = node.source_range

          if array_new?(variable)
            expression = node.parent.source_range if node.parent.array_type?
            [expression, variable.source]
          elsif !variable.array_type?
            [expression, "[#{variable.source}]"]
          elsif redundant_brackets?(node)
            [expression, remove_brackets(variable)]
          else
            [node.loc.operator, '']
          end
        end
        # rubocop:enable Metrics/AbcSize

        def array_splat?(node)
          node.children.first.array_type?
        end

        def method_argument?(node)
          node.parent.call_type?
        end

        def part_of_an_array?(node)
          # The parent of a splat expansion is an array that does not have
          # `begin` or `end`
          parent = node.parent
          parent.array_type? && parent.loc.begin && parent.loc.end
        end

        def redundant_brackets?(node)
          parent = node.parent
          grandparent = node.parent.parent

          parent.when_type? || method_argument?(node) || part_of_an_array?(node) ||
            grandparent&.resbody_type?
        end

        def remove_brackets(array)
          array_start = array.loc.begin.source
          elements = *array
          elements = elements.map(&:source)

          if array_start.start_with?(PERCENT_W)
            "'#{elements.join("', '")}'"
          elsif array_start.start_with?(PERCENT_CAPITAL_W)
            %("#{elements.join('", "')}")
          elsif array_start.start_with?(PERCENT_I)
            ":#{elements.join(', :')}"
          elsif array_start.start_with?(PERCENT_CAPITAL_I)
            %(:"#{elements.join('", :"')}")
          else
            elements.join(', ')
          end
        end

        def use_percent_literal_array_argument?(node)
          argument = node.children.first

          method_argument?(node) &&
            (argument.percent_literal?(:string) || argument.percent_literal?(:symbol))
        end

        def allow_percent_literal_array_argument?
          cop_config.fetch('AllowPercentLiteralArrayArgument', true)
        end
      end
    end
  end
end
