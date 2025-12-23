# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for missing documentation comment for public methods.
      # It can optionally be configured to also require documentation for
      # non-public methods.
      #
      # NOTE: This cop allows `initialize` method because `initialize` is
      # a special method called from `new`. In some programming languages
      # they are called constructor to distinguish it from method.
      #
      # @example
      #
      #   # bad
      #
      #   class Foo
      #     def bar
      #       puts baz
      #     end
      #   end
      #
      #   module Foo
      #     def bar
      #       puts baz
      #     end
      #   end
      #
      #   def foo.bar
      #     puts baz
      #   end
      #
      #   # good
      #
      #   class Foo
      #     # Documentation
      #     def bar
      #       puts baz
      #     end
      #   end
      #
      #   module Foo
      #     # Documentation
      #     def bar
      #       puts baz
      #     end
      #   end
      #
      #   # Documentation
      #   def foo.bar
      #     puts baz
      #   end
      #
      # @example RequireForNonPublicMethods: false (default)
      #   # good
      #   class Foo
      #     protected
      #     def do_something
      #     end
      #   end
      #
      #   class Foo
      #     private
      #     def do_something
      #     end
      #   end
      #
      # @example RequireForNonPublicMethods: true
      #   # bad
      #   class Foo
      #     protected
      #     def do_something
      #     end
      #   end
      #
      #   class Foo
      #     private
      #     def do_something
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     protected
      #     # Documentation
      #     def do_something
      #     end
      #   end
      #
      #   class Foo
      #     private
      #     # Documentation
      #     def do_something
      #     end
      #   end
      #
      # @example AllowedMethods: ['method_missing', 'respond_to_missing?']
      #
      #    # good
      #    class Foo
      #      def method_missing(name, *args)
      #      end
      #
      #      def respond_to_missing?(symbol, include_private)
      #      end
      #    end
      #
      class DocumentationMethod < Base
        include DocumentationComment
        include DefNode

        MSG = 'Missing method documentation comment.'

        # @!method modifier_node?(node)
        def_node_matcher :modifier_node?, <<~PATTERN
          (send nil? {:module_function :ruby2_keywords} ...)
        PATTERN

        def on_def(node)
          return if node.method?(:initialize)

          parent = node.parent
          modifier_node?(parent) ? check(parent) : check(node)
        end
        alias on_defs on_def

        private

        def check(node)
          return if non_public?(node) && !require_for_non_public_methods?
          return if documentation_comment?(node)
          return if method_allowed?(node)

          add_offense(node)
        end

        def require_for_non_public_methods?
          cop_config['RequireForNonPublicMethods']
        end

        def method_allowed?(node)
          allowed_methods.include?(node.method_name)
        end

        def allowed_methods
          @allowed_methods ||= cop_config.fetch('AllowedMethods', []).map(&:to_sym)
        end
      end
    end
  end
end
