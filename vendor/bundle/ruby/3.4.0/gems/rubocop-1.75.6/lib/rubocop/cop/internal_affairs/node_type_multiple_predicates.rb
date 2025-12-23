# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Use `node.type?(:foo, :bar)` instead of `node.foo_type? || node.bar_type?`,
      # and `!node.type?(:foo, :bar)` instead of `!node.foo_type? && !node.bar_type?`.
      #
      # @example
      #
      #   # bad
      #   node.str_type? || node.sym_type?
      #
      #   # good
      #   node.type?(:str, :sym)
      #
      #   # bad
      #   node.type?(:str, :sym) || node.boolean_type?
      #
      #   # good
      #   node.type?(:str, :sym, :boolean)
      #
      #   # bad
      #   !node.str_type? && !node.sym_type?
      #
      #   # good
      #   !node.type?(:str, :sym)
      #
      #   # bad
      #   !node.type?(:str, :sym) && !node.boolean_type?
      #
      #   # good
      #   !node.type?(:str, :sym, :boolean)
      #
      class NodeTypeMultiplePredicates < Base
        extend AutoCorrector

        MSG_OR = 'Use `%<replacement>s` instead of checking for multiple node types.'
        MSG_AND = 'Use `%<replacement>s` instead of checking against multiple node types.'

        # @!method one_of_node_types?(node)
        def_node_matcher :one_of_node_types?, <<~PATTERN
          (or $(call _receiver #type_predicate?) (call _receiver #type_predicate?))
        PATTERN

        # @!method or_another_type?(node)
        def_node_matcher :or_another_type?, <<~PATTERN
          (or {
            $(call _receiver :type? sym+) (call _receiver #type_predicate?) |
            (call _receiver #type_predicate?) $(call _receiver :type? sym+)
          })
        PATTERN

        # @!method none_of_node_types?(node)
        def_node_matcher :none_of_node_types?, <<~PATTERN
          (and
            (send $(call _receiver #type_predicate?) :!)
            (send (call _receiver #type_predicate?) :!)
          )
        PATTERN

        # @!method and_not_another_type?(node)
        def_node_matcher :and_not_another_type?, <<~PATTERN
          (and {
            (send $(call _receiver :type? sym+) :!) (send (call _receiver #type_predicate?) :!) |
            (send (call _receiver #type_predicate?) :!) (send $(call _receiver :type? sym+) :!)
          })
        PATTERN

        def on_or(node)
          return unless (send_node = one_of_node_types?(node) || or_another_type?(node))
          return unless send_node.receiver

          replacement = replacement(node, send_node)
          add_offense(node, message: format(MSG_OR, replacement: replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def on_and(node)
          return unless (send_node = none_of_node_types?(node) || and_not_another_type?(node))
          return unless send_node.receiver

          replacement = "!#{replacement(node, send_node)}"

          add_offense(node, message: format(MSG_AND, replacement: replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        private

        def type_predicate?(method_name)
          method_name.end_with?('_type?')
        end

        def replacement(node, send_node)
          send_node = send_node.children.first if send_node.method?(:!)

          types = types(node)
          receiver = send_node.receiver.source
          dot = send_node.loc.dot.source

          "#{receiver}#{dot}type?(:#{types.join(', :')})"
        end

        def types(node)
          [types_in_branch(node.lhs), types_in_branch(node.rhs)]
        end

        def types_in_branch(branch)
          branch = branch.children.first if branch.method?(:!)

          if branch.method?(:type?)
            branch.arguments.map(&:value)
          elsif branch.method?(:defined_type?)
            # `node.defined_type?` relates to `node.type == :defined?`
            'defined?'
          else
            branch.method_name.to_s.delete_suffix('_type?')
          end
        end
      end
    end
  end
end
