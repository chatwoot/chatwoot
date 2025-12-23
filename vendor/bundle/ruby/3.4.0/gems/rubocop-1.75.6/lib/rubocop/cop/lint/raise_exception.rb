# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `raise` or `fail` statements which raise `Exception` or
      # `Exception.new`. Use `StandardError` or a specific exception class instead.
      #
      # If you have defined your own namespaced `Exception` class, it is possible
      # to configure the cop to allow it by setting `AllowedImplicitNamespaces` to
      # an array with the names of the namespaces to allow. By default, this is set to
      # `['Gem']`, which allows `Gem::Exception` to be raised without an explicit namespace.
      # If not allowed, a false positive may be registered if `raise Exception` is called
      # within the namespace.
      #
      # Alternatively, use a fully qualified name with `raise`/`fail`
      # (eg. `raise Namespace::Exception`).
      #
      # @safety
      #   This cop is unsafe because it will change the exception class being
      #   raised, which is a change in behavior.
      #
      # @example
      #   # bad
      #   raise Exception, 'Error message here'
      #   raise Exception.new('Error message here')
      #
      #   # good
      #   raise StandardError, 'Error message here'
      #   raise MyError.new, 'Error message here'
      #
      # @example AllowedImplicitNamespaces: ['Gem'] (default)
      #   # bad - `Foo` is not an allowed implicit namespace
      #   module Foo
      #     def self.foo
      #       raise Exception # This is qualified to `Foo::Exception`.
      #     end
      #   end
      #
      #   # good
      #   module Gem
      #     def self.foo
      #       raise Exception # This is qualified to `Gem::Exception`.
      #     end
      #   end
      #
      #   # good
      #   module Foo
      #     def self.foo
      #       raise Foo::Exception
      #     end
      #   end
      class RaiseException < Base
        extend AutoCorrector

        MSG = 'Use `StandardError` over `Exception`.'
        RESTRICT_ON_SEND = %i[raise fail].freeze

        # @!method exception?(node)
        def_node_matcher :exception?, <<~PATTERN
          (send nil? {:raise :fail} $(const ${cbase nil?} :Exception) ... )
        PATTERN

        # @!method exception_new_with_message?(node)
        def_node_matcher :exception_new_with_message?, <<~PATTERN
          (send nil? {:raise :fail}
            (send $(const ${cbase nil?} :Exception) :new ... ))
        PATTERN

        def on_send(node)
          exception?(node, &check(node)) || exception_new_with_message?(node, &check(node))
        end

        private

        def check(node)
          lambda do |exception_class, cbase|
            return if cbase.nil? && implicit_namespace?(node)

            add_offense(exception_class) do |corrector|
              prefer_exception = if exception_class.children.first&.cbase_type?
                                   '::StandardError'
                                 else
                                   'StandardError'
                                 end

              corrector.replace(exception_class, prefer_exception)
            end
          end
        end

        def implicit_namespace?(node)
          return false unless (parent = node.parent)

          if parent.module_type?
            namespace = parent.identifier.source

            return allow_implicit_namespaces.include?(namespace)
          end

          implicit_namespace?(parent)
        end

        def allow_implicit_namespaces
          cop_config['AllowedImplicitNamespaces'] || []
        end
      end
    end
  end
end
