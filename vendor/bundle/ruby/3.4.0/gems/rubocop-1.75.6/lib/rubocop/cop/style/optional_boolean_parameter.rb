# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where keyword arguments can be used instead of
      # boolean arguments when defining methods. `respond_to_missing?` method is allowed by default.
      # These are customizable with `AllowedMethods` option.
      #
      # @safety
      #   This cop is unsafe because changing a method signature will
      #   implicitly change behavior.
      #
      # @example
      #   # bad
      #   def some_method(bar = false)
      #     puts bar
      #   end
      #
      #   # bad - common hack before keyword args were introduced
      #   def some_method(options = {})
      #     bar = options.fetch(:bar, false)
      #     puts bar
      #   end
      #
      #   # good
      #   def some_method(bar: false)
      #     puts bar
      #   end
      #
      # @example AllowedMethods: ['some_method']
      #   # good
      #   def some_method(bar = false)
      #     puts bar
      #   end
      #
      class OptionalBooleanParameter < Base
        include AllowedMethods

        MSG = 'Prefer keyword arguments for arguments with a boolean default value; ' \
              'use `%<replacement>s` instead of `%<original>s`.'

        def on_def(node)
          return if allowed_method?(node.method_name)

          node.arguments.each do |arg|
            next unless arg.optarg_type?

            add_offense(arg, message: format_message(arg)) if arg.default_value.boolean_type?
          end
        end
        alias on_defs on_def

        private

        def format_message(argument)
          replacement = "#{argument.name}: #{argument.default_value.source}"

          format(MSG, original: argument.source, replacement: replacement)
        end
      end
    end
  end
end
