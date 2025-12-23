# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that node types are checked against their group when all types of a
      # group are checked.
      #
      # @example
      #   # bad
      #   node.type?(:irange, :erange)
      #
      #   # good
      #   node.range_type?
      #
      #   # bad
      #   node.type?(:irange, :erange, :send, :csend)
      #
      #   # good
      #   node.type?(:range, :call)
      #
      class NodeTypeGroup < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `:%<group>s` instead of individually listing group types.'

        RESTRICT_ON_SEND = %i[type? each_ancestor each_child_node each_descendant each_node].freeze

        def on_send(node)
          return unless node.receiver

          symbol_args = node.arguments.select(&:sym_type?)
          return if symbol_args.none?

          NodePatternGroups::NODE_GROUPS.each do |group_name, group_types|
            next unless group_satisfied?(group_types, symbol_args)

            offense_range = arguments_range(node)
            add_offense(offense_range, message: format(MSG, group: group_name)) do |corrector|
              autocorrect(corrector, node, symbol_args, group_name, group_types)
            end
          end
        end
        alias on_csend on_send

        private

        def arguments_range(node)
          range_between(
            node.first_argument.source_range.begin_pos,
            node.last_argument.source_range.end_pos
          )
        end

        def group_satisfied?(group_types, symbol_args)
          group_types.all? { |type| symbol_args.any? { |arg| arg.value == type } }
        end

        def autocorrect(corrector, node, symbol_args, group_name, group_types)
          if node.method?(:type?) && node.arguments.count == group_types.count
            autocorrect_to_explicit_predicate(corrector, node, group_name)
          else
            autocorrect_keep_method(corrector, symbol_args, group_name, group_types)
          end
        end

        def autocorrect_to_explicit_predicate(corrector, node, group_name)
          corrector.replace(node.selector, "#{group_name}_type?")
          corrector.remove(arguments_range(node))
        end

        def autocorrect_keep_method(corrector, symbol_args, group_name, group_types)
          first_replaced = false
          symbol_args.each do |arg|
            next unless group_types.include?(arg.value)

            if first_replaced
              range = range_with_surrounding_space(arg.source_range)
              range = range_with_surrounding_comma(range, :left)
              corrector.remove(range)
            else
              first_replaced = true
              corrector.replace(arg, ":#{group_name}")
            end
          end
        end
      end
    end
  end
end
