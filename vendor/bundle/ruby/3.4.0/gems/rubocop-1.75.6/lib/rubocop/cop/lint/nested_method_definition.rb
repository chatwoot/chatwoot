# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for nested method definitions.
      #
      # @example
      #
      #   # bad
      #
      #   # `bar` definition actually produces methods in the same scope
      #   # as the outer `foo` method. Furthermore, the `bar` method
      #   # will be redefined every time `foo` is invoked.
      #   def foo
      #     def bar
      #     end
      #   end
      #
      #   # good
      #
      #   def foo
      #     bar = -> { puts 'hello' }
      #     bar.call
      #   end
      #
      #   # good
      #
      #   # `class_eval`, `instance_eval`, `module_eval`, `class_exec`, `instance_exec`, and
      #   # `module_exec` blocks are allowed by default.
      #
      #   def foo
      #     self.class.class_eval do
      #       def bar
      #       end
      #     end
      #   end
      #
      #   def foo
      #     self.class.module_exec do
      #       def bar
      #       end
      #     end
      #   end
      #
      #   # good
      #
      #   def foo
      #     class << self
      #       def bar
      #       end
      #     end
      #   end
      #
      # @example AllowedMethods: [] (default)
      #   # bad
      #   def do_something
      #     has_many :articles do
      #       def find_or_create_by_name(name)
      #       end
      #     end
      #   end
      #
      # @example AllowedMethods: ['has_many']
      #   # bad
      #   def do_something
      #     has_many :articles do
      #       def find_or_create_by_name(name)
      #       end
      #     end
      #   end
      #
      # @example AllowedPatterns: [] (default)
      #   # bad
      #   def foo(obj)
      #     obj.do_baz do
      #       def bar
      #       end
      #     end
      #   end
      #
      # @example AllowedPatterns: ['baz']
      #   # good
      #   def foo(obj)
      #     obj.do_baz do
      #       def bar
      #       end
      #     end
      #   end
      #
      class NestedMethodDefinition < Base
        include AllowedMethods
        include AllowedPattern

        MSG = 'Method definitions must not be nested. Use `lambda` instead.'

        def on_def(node)
          subject, = *node # rubocop:disable InternalAffairs/NodeDestructuring
          return if node.defs_type? && allowed_subject_type?(subject)

          def_ancestor = node.each_ancestor(:any_def).first
          return unless def_ancestor

          within_scoping_def =
            node.each_ancestor(:any_block, :sclass).any? do |ancestor|
              scoping_method_call?(ancestor)
            end

          add_offense(node) if def_ancestor && !within_scoping_def
        end
        alias on_defs on_def

        private

        def scoping_method_call?(child)
          child.sclass_type? || eval_call?(child) || exec_call?(child) ||
            child.class_constructor? || allowed_method_name?(child)
        end

        def allowed_subject_type?(subject)
          subject.variable? || subject.const_type? || subject.call_type?
        end

        def allowed_method_name?(node)
          name = node.method_name

          allowed_method?(name) || matches_allowed_pattern?(name)
        end

        # @!method eval_call?(node)
        def_node_matcher :eval_call?, <<~PATTERN
          (any_block (send _ {:instance_eval :class_eval :module_eval} ...) ...)
        PATTERN

        # @!method exec_call?(node)
        def_node_matcher :exec_call?, <<~PATTERN
          (any_block (send _ {:instance_exec :class_exec :module_exec} ...) ...)
        PATTERN
      end
    end
  end
end
