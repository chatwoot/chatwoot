# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for delegations that could have been created
      # automatically with the `delegate` method.
      #
      # Safe navigation `&.` is ignored because Rails' `allow_nil`
      # option checks not just for nil but also delegates if nil
      # responds to the delegated method.
      #
      # The `EnforceForPrefixed` option (defaulted to `true`) means that
      # using the target object as a prefix of the method name
      # without using the `delegate` method will be a violation.
      # When set to `false`, this case is legal.
      #
      # It is disabled for controllers in order to keep controller actions
      # explicitly defined.
      #
      # @example
      #   # bad
      #   def bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo
      #
      #   # bad
      #   def bar
      #     self.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :self
      #
      #   # good
      #   def bar
      #     foo&.bar
      #   end
      #
      #   # good
      #   private
      #   def bar
      #     foo.bar
      #   end
      #
      # @example EnforceForPrefixed: true (default)
      #   # bad
      #   def foo_bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo, prefix: true
      #
      # @example EnforceForPrefixed: false
      #   # good
      #   def foo_bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo, prefix: true
      class Delegate < Base
        extend AutoCorrector
        include VisibilityHelp

        MSG = 'Use `delegate` to define delegations.'

        def_node_matcher :delegate?, <<~PATTERN
          (def _method_name _args
            (send {(send nil? _) (self) (send (self) :class) ({cvar gvar ivar} _) (const _ _)} _ ...))
        PATTERN

        def on_def(node)
          return unless trivial_delegate?(node)
          return if private_or_protected_delegation(node)
          return if module_function_declared?(node)

          register_offense(node)
        end

        private

        def register_offense(node)
          add_offense(node.loc.keyword) do |corrector|
            receiver = determine_register_offense_receiver(node.body.receiver)
            delegation = build_delegation(node, receiver)

            corrector.replace(node, delegation)
          end
        end

        def determine_register_offense_receiver(receiver)
          case receiver.type
          when :self
            'self'
          when :const
            full_name = full_const_name(receiver)
            full_name.include?('::') ? ":'#{full_name}'" : ":#{full_name}"
          when :cvar, :gvar, :ivar
            ":#{receiver.source}"
          else
            ":#{receiver.method_name}"
          end
        end

        def build_delegation(node, receiver)
          delegation = ["delegate :#{node.body.method_name}", "to: #{receiver}"]
          delegation << ['prefix: true'] if node.method?(prefixed_method_name(node.body))
          delegation.join(', ')
        end

        def full_const_name(node)
          return unless node.const_type?
          unless node.namespace
            return node.absolute? ? "::#{node.source}" : node.source
          end

          "#{full_const_name(node.namespace)}::#{node.short_name}"
        end

        def trivial_delegate?(def_node)
          delegate?(def_node) &&
            method_name_matches?(def_node.method_name, def_node.body) &&
            arguments_match?(def_node.arguments, def_node.body)
        end

        def arguments_match?(arg_array, body)
          argument_array = body.arguments

          return false if arg_array.size != argument_array.size

          arg_array.zip(argument_array).all? do |arg, argument|
            arg.arg_type? && argument.lvar_type? && arg.children == argument.children
          end
        end

        def method_name_matches?(method_name, body)
          method_name == body.method_name || (include_prefix_case? && method_name == prefixed_method_name(body))
        end

        def include_prefix_case?
          cop_config['EnforceForPrefixed']
        end

        def prefixed_method_name(body)
          return '' if body.receiver.self_type?

          [determine_prefixed_method_receiver_name(body.receiver), body.method_name].join('_').to_sym
        end

        def determine_prefixed_method_receiver_name(receiver)
          case receiver.type
          when :cvar, :gvar, :ivar
            receiver.source
          when :const
            full_const_name(receiver)
          else
            receiver.method_name.to_s
          end
        end

        def private_or_protected_delegation(node)
          private_or_protected_inline(node) || node_visibility(node) != :public
        end

        def module_function_declared?(node)
          node.each_ancestor(:module, :begin).any? do |ancestor|
            ancestor.children.any? { |child| child.send_type? && child.method?(:module_function) }
          end
        end

        def private_or_protected_inline(node)
          processed_source[node.first_line - 1].strip.match?(/\A(private )|(protected )/)
        end
      end
    end
  end
end
