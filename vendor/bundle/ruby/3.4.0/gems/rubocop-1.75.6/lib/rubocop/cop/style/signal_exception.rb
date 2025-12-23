# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of `fail` and `raise`.
      #
      # @example EnforcedStyle: only_raise (default)
      #   # The `only_raise` style enforces the sole use of `raise`.
      #   # bad
      #   begin
      #     fail
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     fail
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   Kernel.fail
      #
      #   # good
      #   begin
      #     raise
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     raise
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   Kernel.raise
      #
      # @example EnforcedStyle: only_fail
      #   # The `only_fail` style enforces the sole use of `fail`.
      #   # bad
      #   begin
      #     raise
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     raise
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   Kernel.raise
      #
      #   # good
      #   begin
      #     fail
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     fail
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   Kernel.fail
      #
      # @example EnforcedStyle: semantic
      #   # The `semantic` style enforces the use of `fail` to signal an
      #   # exception, then will use `raise` to trigger an offense after
      #   # it has been rescued.
      #   # bad
      #   begin
      #     raise
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     # Error thrown
      #   rescue Exception
      #     fail
      #   end
      #
      #   Kernel.fail
      #   Kernel.raise
      #
      #   # good
      #   begin
      #     fail
      #   rescue Exception
      #     # handle it
      #   end
      #
      #   def watch_out
      #     fail
      #   rescue Exception
      #     raise 'Preferably with descriptive message'
      #   end
      #
      #   explicit_receiver.fail
      #   explicit_receiver.raise
      class SignalException < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        FAIL_MSG = 'Use `fail` instead of `raise` to signal exceptions.'
        RAISE_MSG = 'Use `raise` instead of `fail` to rethrow exceptions.'

        RESTRICT_ON_SEND = %i[raise fail].freeze

        # @!method kernel_call?(node, name)
        def_node_matcher :kernel_call?, '(send (const {nil? cbase} :Kernel) %1 ...)'

        # @!method custom_fail_methods(node)
        def_node_search :custom_fail_methods, '{(def :fail ...) (defs _ :fail ...)}'

        def on_rescue(node)
          return unless style == :semantic

          check_scope(:raise, node.body)

          node.resbody_branches.each do |rescue_node|
            check_scope(:fail, rescue_node)
            allow(:raise, rescue_node)
          end
        end

        def on_send(node)
          case style
          when :semantic
            check_send(:raise, node) unless ignored_node?(node)
          when :only_raise
            return if custom_fail_defined?

            check_send(:fail, node)
          when :only_fail
            check_send(:raise, node)
          end
        end

        private

        def custom_fail_defined?
          return @custom_fail_defined if defined?(@custom_fail_defined)

          ast = processed_source.ast
          @custom_fail_defined = ast && custom_fail_methods(ast).any?
        end

        def message(method_name)
          case style
          when :semantic
            method_name == :fail ? RAISE_MSG : FAIL_MSG
          when :only_raise
            'Always use `raise` to signal exceptions.'
          when :only_fail
            'Always use `fail` to signal exceptions.'
          end
        end

        def check_scope(method_name, node)
          return unless node

          each_command_or_kernel_call(method_name, node) do |send_node|
            next if ignored_node?(send_node)

            add_offense(send_node.loc.selector, message: message(method_name)) do |corrector|
              autocorrect(corrector, send_node)
            end
            ignore_node(send_node)
          end
        end

        def check_send(method_name, node)
          return unless node && command_or_kernel_call?(method_name, node)

          add_offense(node.loc.selector, message: message(method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect(corrector, node)
          name =
            case style
            when :semantic
              command_or_kernel_call?(:raise, node) ? 'fail' : 'raise'
            when :only_raise then 'raise'
            when :only_fail then 'fail'
            end

          corrector.replace(node.loc.selector, name)
        end

        def command_or_kernel_call?(name, node)
          return false unless node.method?(name)

          node.command?(name) || kernel_call?(node, name)
        end

        def allow(method_name, node)
          each_command_or_kernel_call(method_name, node) { |send_node| ignore_node(send_node) }
        end

        def each_command_or_kernel_call(method_name, node)
          on_node(:send, node, :rescue) do |send_node|
            yield send_node if command_or_kernel_call?(method_name, send_node)
          end
        end
      end
    end
  end
end
