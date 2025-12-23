# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for debug calls (such as `debugger` or `binding.pry`) that should
      # not be kept for production code.
      #
      # The cop can be configured using `DebuggerMethods`. By default, a number of gems
      # debug entrypoints are configured (`Kernel`, `Byebug`, `Capybara`, `debug.rb`,
      # `Pry`, `Rails`, `RubyJard`, and `WebConsole`). Additional methods can be added.
      #
      # Specific default groups can be disabled if necessary:
      #
      # [source,yaml]
      # ----
      # Lint/Debugger:
      #   DebuggerMethods:
      #     WebConsole: ~
      # ----
      #
      # You can also add your own methods by adding a new category:
      #
      # [source,yaml]
      # ----
      # Lint/Debugger:
      #   DebuggerMethods:
      #     MyDebugger:
      #       MyDebugger.debug_this
      # ----
      #
      # Some gems also ship files that will start a debugging session when required,
      # for example `require 'debug/start'` from `ruby/debug`. These requires can
      # be configured through `DebuggerRequires`. It has the same structure as
      # `DebuggerMethods`, which you can read about above.
      #
      # @example
      #
      #   # bad (ok during development)
      #
      #   # using pry
      #   def some_method
      #     binding.pry
      #     do_something
      #   end
      #
      #   # bad (ok during development)
      #
      #   # using byebug
      #   def some_method
      #     byebug
      #     do_something
      #   end
      #
      #   # good
      #
      #   def some_method
      #     do_something
      #   end
      #
      # @example DebuggerMethods: [my_debugger]
      #
      #   # bad (ok during development)
      #
      #   def some_method
      #     my_debugger
      #   end
      #
      # @example DebuggerRequires: [my_debugger/start]
      #
      #   # bad (ok during development)
      #
      #   require 'my_debugger/start'
      class Debugger < Base
        MSG = 'Remove debugger entry point `%<source>s`.'
        BLOCK_TYPES = %i[block numblock itblock kwbegin].freeze

        def on_send(node)
          return if assumed_usage_context?(node)

          add_offense(node) if debugger_method?(node) || debugger_require?(node)
        end

        private

        def message(node)
          format(MSG, source: node.source)
        end

        def debugger_methods
          @debugger_methods ||= begin
            config = cop_config.fetch('DebuggerMethods', [])
            config.is_a?(Array) ? config : config.values.flatten
          end
        end

        def debugger_requires
          @debugger_requires ||= begin
            config = cop_config.fetch('DebuggerRequires', [])
            config.is_a?(Array) ? config : config.values.flatten
          end
        end

        def debugger_method?(send_node)
          return false if send_node.parent&.send_type? && send_node.parent.receiver == send_node

          debugger_methods.include?(chained_method_name(send_node))
        end

        def debugger_require?(send_node)
          return false unless send_node.method?(:require) && send_node.arguments.one?
          return false unless (argument = send_node.first_argument).str_type?

          debugger_requires.include?(argument.value)
        end

        def assumed_usage_context?(node)
          # Basically, debugger methods are not used as a method argument without arguments.
          return false unless node.arguments.empty? && node.each_ancestor(:call).any?
          return true if assumed_argument?(node)

          node.each_ancestor.none? do |ancestor|
            ancestor.type?(:any_block, :kwbegin) || ancestor.lambda_or_proc?
          end
        end

        def chained_method_name(send_node)
          chained_method_name = send_node.method_name.to_s
          receiver = send_node.receiver
          while receiver
            name = receiver.send_type? ? receiver.method_name : receiver.const_name
            chained_method_name = "#{name}.#{chained_method_name}"
            receiver = receiver.receiver
          end
          chained_method_name
        end

        def assumed_argument?(node)
          parent = node.parent

          parent.call_type? || parent.literal? || parent.pair_type?
        end
      end
    end
  end
end
