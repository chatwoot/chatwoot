# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for inject / reduce calls where the passed in object is
      # returned at the end and so could be replaced by each_with_object without
      # the need to return the object at the end.
      #
      # However, we can't replace with each_with_object if the accumulator
      # parameter is assigned to within the block.
      #
      # @example
      #   # bad
      #   [1, 2].inject({}) { |a, e| a[e] = e; a }
      #
      #   # good
      #   [1, 2].each_with_object({}) { |e, a| a[e] = e }
      class EachWithObject < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `each_with_object` instead of `%<method>s`.'
        METHODS = %i[inject reduce].freeze

        def on_block(node)
          each_with_object_block_candidate?(node) do |method, args, body|
            _, method_name, method_arg = *method
            return if simple_method_arg?(method_arg)

            return_value = return_value(body)
            return unless return_value
            return unless first_argument_returned?(args, return_value)
            return if accumulator_param_assigned_to?(body, args)

            message = format(MSG, method: method_name)
            add_offense(method.loc.selector, message: message) do |corrector|
              autocorrect_block(corrector, node, return_value)
            end
          end
        end

        def on_numblock(node)
          each_with_object_numblock_candidate?(node) do |method, body|
            _, method_name, method_arg = *method
            return if simple_method_arg?(method_arg)

            return unless return_value(body)&.source == '_1'

            message = format(MSG, method: method_name)
            add_offense(method.loc.selector, message: message) do |corrector|
              autocorrect_numblock(corrector, node)
            end
          end
        end

        private

        # @!method each_with_object_block_candidate?(node)
        def_node_matcher :each_with_object_block_candidate?, <<~PATTERN
          (block $(call _ {:inject :reduce} _) $(args _ _) $_)
        PATTERN

        # @!method each_with_object_numblock_candidate?(node)
        def_node_matcher :each_with_object_numblock_candidate?, <<~PATTERN
          (numblock $(call _ {:inject :reduce} _) 2 $_)
        PATTERN

        def autocorrect_block(corrector, node, return_value)
          corrector.replace(node.send_node.loc.selector, 'each_with_object')

          first_arg, second_arg = *node.arguments

          corrector.swap(first_arg, second_arg)

          if return_value_occupies_whole_line?(return_value)
            corrector.remove(whole_line_expression(return_value))
          else
            corrector.remove(return_value)
          end
        end

        def autocorrect_numblock(corrector, node)
          corrector.replace(node.send_node.loc.selector, 'each_with_object')

          # We don't remove the return value to avoid a clobbering error.
          node.body.each_descendant do |var|
            next unless var.lvar_type?

            corrector.replace(var, '_2') if var.source == '_1'
            corrector.replace(var, '_1') if var.source == '_2'
          end
        end

        def simple_method_arg?(method_arg)
          method_arg&.basic_literal?
        end

        # if the accumulator parameter is assigned to in the block,
        # then we can't convert to each_with_object
        def accumulator_param_assigned_to?(body, args)
          first_arg, = *args
          accumulator_var, = *first_arg

          body.each_descendant.any? do |n|
            next unless n.assignment?

            lhs, _rhs = *n
            lhs.equal?(accumulator_var)
          end
        end

        def return_value(body)
          return unless body

          return_value = body.begin_type? ? body.children.last : body
          return_value if return_value&.lvar_type?
        end

        def first_argument_returned?(args, return_value)
          first_arg, = *args
          accumulator_var, = *first_arg
          return_var, = *return_value

          accumulator_var == return_var
        end

        def return_value_occupies_whole_line?(node)
          whole_line_expression(node).source.strip == node.source
        end

        def whole_line_expression(node)
          range_by_whole_lines(node.source_range, include_final_newline: true)
        end
      end
    end
  end
end
