# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that are a kind of method dispatch:
    # `send`, `csend`, `super`, `zsuper`, `yield`, `defined?`,
    # and (modern only): `index`, `indexasgn`, `lambda`
    module MethodDispatchNode # rubocop:disable Metrics/ModuleLength
      extend NodePattern::Macros
      include MethodIdentifierPredicates

      ARITHMETIC_OPERATORS = %i[+ - * / % **].freeze
      private_constant :ARITHMETIC_OPERATORS
      SPECIAL_MODIFIERS = %w[private protected].freeze
      private_constant :SPECIAL_MODIFIERS

      # The receiving node of the method dispatch.
      #
      # @return [Node, nil] the receiver of the dispatched method or `nil`
      def receiver
        node_parts[0]
      end

      # The name of the dispatched method as a symbol.
      #
      # @return [Symbol] the name of the dispatched method
      def method_name
        node_parts[1]
      end

      # The source range for the method name or keyword that dispatches this call.
      #
      # @return [Parser::Source::Range] the source range for the method name or keyword
      def selector
        if loc.respond_to? :keyword
          loc.keyword
        else
          loc.selector
        end
      end

      # The `block`, `numblock`, or `itblock` node associated with this method dispatch, if any.
      #
      # @return [BlockNode, nil] the `block`, `numblock`, or `itblock` node associated with this
      #                          method call or `nil`
      def block_node
        parent if block_literal?
      end

      # Checks whether the dispatched method is a macro method. A macro method
      # is defined as a method that sits in a class, module, or block body and
      # has an implicit receiver.
      #
      # @note This does not include DSLs that use nested blocks, like RSpec
      #
      # @return [Boolean] whether the dispatched method is a macro method
      def macro?
        !receiver && in_macro_scope?
      end

      # Checks whether the dispatched method is an access modifier.
      #
      # @return [Boolean] whether the dispatched method is an access modifier
      def access_modifier?
        bare_access_modifier? || non_bare_access_modifier?
      end

      # Checks whether the dispatched method is a bare access modifier that
      # affects all methods defined after the macro.
      #
      # @return [Boolean] whether the dispatched method is a bare
      #                   access modifier
      def bare_access_modifier?
        macro? && bare_access_modifier_declaration?
      end

      # Checks whether the dispatched method is a non-bare access modifier that
      # affects only the method it receives.
      #
      # @return [Boolean] whether the dispatched method is a non-bare
      #                   access modifier
      def non_bare_access_modifier?
        macro? && non_bare_access_modifier_declaration?
      end

      # Checks whether the dispatched method is a bare `private` or `protected`
      # access modifier that affects all methods defined after the macro.
      #
      # @return [Boolean] whether the dispatched method is a bare
      #                    `private` or `protected` access modifier
      def special_modifier?
        bare_access_modifier? && SPECIAL_MODIFIERS.include?(source)
      end

      # Checks whether the name of the dispatched method matches the argument
      # and has an implicit receiver.
      #
      # @param [Symbol, String] name the method name to check for
      # @return [Boolean] whether the method name matches the argument
      def command?(name)
        !receiver && method?(name)
      end

      # Checks whether the dispatched method is a setter method.
      #
      # @return [Boolean] whether the dispatched method is a setter
      def setter_method?
        loc?(:operator)
      end
      alias assignment? setter_method?

      # Checks whether the dispatched method uses a dot to connect the
      # receiver and the method name.
      #
      # This is useful for comparison operators, which can be called either
      # with or without a dot, i.e. `foo == bar` or `foo.== bar`.
      #
      # @return [Boolean] whether the method was called with a connecting dot
      def dot?
        loc_is?(:dot, '.')
      end

      # Checks whether the dispatched method uses a double colon to connect the
      # receiver and the method name.
      #
      # @return [Boolean] whether the method was called with a connecting dot
      def double_colon?
        loc_is?(:dot, '::')
      end

      # Checks whether the dispatched method uses a safe navigation operator to
      # connect the receiver and the method name.
      #
      # @return [Boolean] whether the method was called with a connecting dot
      def safe_navigation?
        loc_is?(:dot, '&.')
      end

      # Checks whether the *explicit* receiver of this method dispatch is
      # `self`.
      #
      # @return [Boolean] whether the receiver of this method dispatch is `self`
      def self_receiver?
        receiver&.self_type?
      end

      # Checks whether the *explicit* receiver of this method dispatch is a
      # `const` node.
      #
      # @return [Boolean] whether the receiver of this method dispatch
      #                   is a `const` node
      def const_receiver?
        receiver&.const_type?
      end

      # Checks whether the method dispatch is the implicit form of `#call`,
      # e.g. `foo.(bar)`.
      #
      # @return [Boolean] whether the method is the implicit form of `#call`
      def implicit_call?
        method?(:call) && !selector
      end

      # Whether this method dispatch has an explicit block.
      #
      # @return [Boolean] whether the dispatched method has a block
      def block_literal?
        parent&.any_block_type? && eql?(parent.send_node)
      end

      # Checks whether this node is an arithmetic operation
      #
      # @return [Boolean] whether the dispatched method is an arithmetic
      #                   operation
      def arithmetic_operation?
        ARITHMETIC_OPERATORS.include?(method_name)
      end

      # Checks if this node is part of a chain of `def` or `defs` modifiers.
      #
      # @example
      #
      #   private def foo; end
      #
      # @return whether the `def|defs` node is a modifier or not.
      # See also `def_modifier` that returns the node or `nil`
      def def_modifier?(node = self)
        !!def_modifier(node)
      end

      # Checks if this node is part of a chain of `def` or `defs` modifiers.
      #
      # @example
      #
      #   private def foo; end
      #
      # @return [Node | nil] returns the `def|defs` node this is a modifier for,
      # or `nil` if it isn't a def modifier
      def def_modifier(node = self)
        arg = node.children[2]

        return unless node.send_type? && node.receiver.nil? && arg.is_a?(::AST::Node)
        return arg if arg.any_def_type?

        def_modifier(arg)
      end

      # Checks whether this is a lambda. Some versions of parser parses
      # non-literal lambdas as a method send.
      #
      # @return [Boolean] whether this method is a lambda
      def lambda?
        block_literal? && command?(:lambda)
      end

      # Checks whether this is a lambda literal (stabby lambda.)
      #
      # @example
      #
      #   -> (foo) { bar }
      #
      # @return [Boolean] whether this method is a lambda literal
      def lambda_literal?
        loc.expression.source == '->' && block_literal?
      end

      # Checks whether this is a unary operation.
      #
      # @example
      #
      #   -foo
      #
      # @return [Boolean] whether this method is a unary operation
      def unary_operation?
        return false unless selector

        operator_method? && loc.expression.begin_pos == selector.begin_pos
      end

      # Checks whether this is a binary operation.
      #
      # @example
      #
      #   foo + bar
      #
      # @return [Boolean] whether this method is a binary operation
      def binary_operation?
        return false unless selector

        operator_method? && loc.expression.begin_pos != selector.begin_pos
      end

      private

      # @!method in_macro_scope?(node = self)
      def_node_matcher :in_macro_scope?, <<~PATTERN
        {
          root?                                    # Either a root node,
          ^{                                       # or the parent is...
            sclass class module class_constructor? # a class-like node
            [ {                                    # or some "wrapper"
                kwbegin begin any_block
                (if _condition <%0 _>)  # note: we're excluding the condition of `if` nodes
              }
              #in_macro_scope?                     # that is itself in a macro scope
            ]
          }
        }
      PATTERN

      # @!method adjacent_def_modifier?(node = self)
      def_node_matcher :adjacent_def_modifier?, <<~PATTERN
        (send nil? _ (any_def ...))
      PATTERN

      # @!method bare_access_modifier_declaration?(node = self)
      def_node_matcher :bare_access_modifier_declaration?, <<~PATTERN
        (send nil? {:public :protected :private :module_function})
      PATTERN

      # @!method non_bare_access_modifier_declaration?(node = self)
      def_node_matcher :non_bare_access_modifier_declaration?, <<~PATTERN
        (send nil? {:public :protected :private :module_function} _+)
      PATTERN
    end
  end
end
