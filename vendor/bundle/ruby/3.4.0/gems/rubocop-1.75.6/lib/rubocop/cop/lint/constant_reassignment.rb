# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for constant reassignments.
      #
      # Emulates Ruby's runtime warning "already initialized constant X"
      # when a constant is reassigned in the same file and namespace using the
      # `NAME = value` syntax.
      #
      # The cop cannot catch all offenses, like, for example, when a constant
      # is reassigned in another file, or when using metaprogramming (`Module#const_set`).
      #
      # The cop only takes into account constants assigned in a "simple" way: directly
      # inside class/module definition, or within another constant. Other type of assignments
      # (e.g., inside a conditional) are disregarded.
      #
      # The cop also tracks constant removal using `Module#remove_const` with symbol
      # or string argument.
      #
      # @example
      #   # bad
      #   X = :foo
      #   X = :bar
      #
      #   # bad
      #   class A
      #     X = :foo
      #     X = :bar
      #   end
      #
      #   # bad
      #   module A
      #     X = :foo
      #     X = :bar
      #   end
      #
      #   # good - keep only one assignment
      #   X = :bar
      #
      #   class A
      #     X = :bar
      #   end
      #
      #   module A
      #     X = :bar
      #   end
      #
      #   # good - use OR assignment
      #   X = :foo
      #   X ||= :bar
      #
      #   # good - use conditional assignment
      #   X = :foo
      #   X = :bar unless defined?(X)
      #
      #   # good - remove the assigned constant first
      #   class A
      #     X = :foo
      #     remove_const :X
      #     X = :bar
      #   end
      #
      class ConstantReassignment < Base
        MSG = 'Constant `%<constant>s` is already assigned in this namespace.'

        RESTRICT_ON_SEND = %i[remove_const].freeze

        # @!method remove_constant(node)
        def_node_matcher :remove_constant, <<~PATTERN
          (send _ :remove_const
            ({sym str} $_))
        PATTERN

        def on_casgn(node)
          return unless fixed_constant_path?(node)
          return unless simple_assignment?(node)
          return if constant_names.add?(fully_qualified_constant_name(node))

          add_offense(node, message: format(MSG, constant: node.name))
        end

        def on_send(node)
          constant = remove_constant(node)

          return unless constant

          namespaces = ancestor_namespaces(node)

          return if namespaces.none?

          constant_names.delete(fully_qualified_name_for(namespaces, constant))
        end

        private

        def fixed_constant_path?(node)
          node.each_path.all? { |path| path.type?(:cbase, :const, :self) }
        end

        def simple_assignment?(node)
          node.ancestors.all? do |ancestor|
            return true if ancestor.type?(:module, :class)

            ancestor.begin_type? || ancestor.literal? || ancestor.casgn_type? ||
              freeze_method?(ancestor)
          end
        end

        def freeze_method?(node)
          node.send_type? && node.method?(:freeze)
        end

        def fully_qualified_constant_name(node)
          if node.absolute?
            namespace = node.namespace.const_type? ? node.namespace.source : nil

            "#{namespace}::#{node.name}"
          else
            constant_namespaces = ancestor_namespaces(node) + constant_namespaces(node)

            fully_qualified_name_for(constant_namespaces, node.name)
          end
        end

        def fully_qualified_name_for(namespaces, constant)
          ['', *namespaces, constant].join('::')
        end

        def constant_namespaces(node)
          node.each_path.select(&:const_type?).map(&:short_name)
        end

        def ancestor_namespaces(node)
          node
            .each_ancestor(:class, :module)
            .map { |ancestor| ancestor.identifier.short_name }
            .reverse
        end

        def constant_names
          @constant_names ||= Set.new
        end
      end
    end
  end
end
