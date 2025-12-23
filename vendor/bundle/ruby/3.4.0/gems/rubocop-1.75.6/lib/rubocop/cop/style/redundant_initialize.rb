# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `initialize` methods that are redundant.
      #
      # An initializer is redundant if it does not do anything, or if it only
      # calls `super` with the same arguments given to it. If the initializer takes
      # an argument that accepts multiple values (`restarg`, `kwrestarg`, etc.) it
      # will not register an offense, because it allows the initializer to take a different
      # number of arguments as its superclass potentially does.
      #
      # NOTE: If an initializer takes any arguments and has an empty body, RuboCop
      # assumes it to *not* be redundant. This is to prevent potential `ArgumentError`.
      #
      # NOTE: If an initializer argument has a default value, RuboCop assumes it
      # to *not* be redundant.
      #
      # NOTE: Empty initializers are registered as offenses, but it is possible
      # to purposely create an empty `initialize` method to override a superclass's
      # initializer.
      #
      # @safety
      #   This cop is unsafe because removing an empty initializer may alter
      #   the behavior of the code, particularly if the superclass initializer
      #   raises an exception. In such cases, the empty initializer may act as
      #   a safeguard to prevent unintended errors from propagating.
      #
      # @example
      #   # bad
      #   def initialize
      #   end
      #
      #   # bad
      #   def initialize
      #     super
      #   end
      #
      #   # bad
      #   def initialize(a, b)
      #     super
      #   end
      #
      #   # bad
      #   def initialize(a, b)
      #     super(a, b)
      #   end
      #
      #   # good
      #   def initialize
      #     do_something
      #   end
      #
      #   # good
      #   def initialize
      #     do_something
      #     super
      #   end
      #
      #   # good (different number of parameters)
      #   def initialize(a, b)
      #     super(a)
      #   end
      #
      #   # good (default value)
      #   def initialize(a, b = 5)
      #     super
      #   end
      #
      #   # good (default value)
      #   def initialize(a, b: 5)
      #     super
      #   end
      #
      #   # good (changes the parameter requirements)
      #   def initialize(_)
      #   end
      #
      #   # good (changes the parameter requirements)
      #   def initialize(*)
      #   end
      #
      #   # good (changes the parameter requirements)
      #   def initialize(**)
      #   end
      #
      #   # good (changes the parameter requirements)
      #   def initialize(...)
      #   end
      #
      # @example AllowComments: true (default)
      #
      #   # good
      #   def initialize
      #     # Overriding to negate superclass `initialize` method.
      #   end
      #
      # @example AllowComments: false
      #
      #   # bad
      #   def initialize
      #     # Overriding to negate superclass `initialize` method.
      #   end
      #
      class RedundantInitialize < Base
        include CommentsHelp
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove unnecessary `initialize` method.'
        MSG_EMPTY = 'Remove unnecessary empty `initialize` method.'

        # @!method initialize_forwards?(node)
        def_node_matcher :initialize_forwards?, <<~PATTERN
          (def _ (args $arg*) $({super zsuper} ...))
        PATTERN

        def on_def(node)
          return if acceptable?(node)

          if node.body.nil?
            register_offense(node, MSG_EMPTY) if node.arguments.empty?
          else
            return if node.body.begin_type?

            if (args, super_node = initialize_forwards?(node))
              return unless same_args?(super_node, args)

              register_offense(node, MSG)
            end
          end
        end

        private

        def register_offense(node, message)
          add_offense(node, message: message) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
          end
        end

        def acceptable?(node)
          !node.method?(:initialize) || forwards?(node) || allow_comments?(node)
        end

        def forwards?(node)
          node.arguments.each_child_node(:restarg, :kwrestarg, :forward_args, :forward_arg).any?
        end

        def allow_comments?(node)
          return false unless cop_config['AllowComments']

          contains_comments?(node) && !comments_contain_disables?(node, name)
        end

        def same_args?(super_node, args)
          return true if super_node.zsuper_type?

          args.map(&:name) == super_node.arguments.map { |a| a.children[0] }
        end
      end
    end
  end
end
