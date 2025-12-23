# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for useless constant scoping. Private constants must be defined using
      # `private_constant`. Even if `private` access modifier is used, it is public scope despite
      # its appearance.
      #
      # It does not support autocorrection due to behavior change and multiple ways to fix it.
      # Or a public constant may be intended.
      #
      # @example
      #
      #   # bad
      #   class Foo
      #     private
      #     PRIVATE_CONST = 42
      #   end
      #
      #   # good
      #   class Foo
      #     PRIVATE_CONST = 42
      #     private_constant :PRIVATE_CONST
      #   end
      #
      #   # good
      #   class Foo
      #     PUBLIC_CONST = 42 # If private scope is not intended.
      #   end
      #
      class UselessConstantScoping < Base
        MSG = 'Useless `private` access modifier for constant scope.'

        # @!method private_constants(node)
        def_node_matcher :private_constants, <<~PATTERN
          (send nil? :private_constant $...)
        PATTERN

        def on_casgn(node)
          return unless after_private_modifier?(node.left_siblings)
          return if private_constantize?(node.right_siblings, node.name)

          add_offense(node)
        end

        private

        def after_private_modifier?(left_siblings)
          access_modifier_candidates = left_siblings.compact.select do |left_sibling|
            left_sibling.respond_to?(:send_type?) && left_sibling.send_type?
          end

          access_modifier_candidates.any? do |candidate|
            candidate.command?(:private) && candidate.arguments.none?
          end
        end

        def private_constantize?(right_siblings, const_value)
          private_constant_arguments = right_siblings.map { |node| private_constants(node) }

          private_constant_values = private_constant_arguments.flatten.filter_map do |constant|
            constant.value.to_sym if constant.respond_to?(:value)
          end

          private_constant_values.include?(const_value)
        end
      end
    end
  end
end
