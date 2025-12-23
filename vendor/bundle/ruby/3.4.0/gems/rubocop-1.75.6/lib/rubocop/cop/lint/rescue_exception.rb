# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `rescue` blocks targeting the `Exception` class.
      #
      # @example
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue Exception
      #     handle_exception
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue ArgumentError
      #     handle_exception
      #   end
      class RescueException < Base
        MSG = 'Avoid rescuing the `Exception` class. Perhaps you meant to rescue `StandardError`?'

        def on_resbody(node)
          return unless node.children.first

          rescue_args = node.children.first.children
          return unless rescue_args.any? { |a| targets_exception?(a) }

          add_offense(node)
        end

        def targets_exception?(rescue_arg_node)
          rescue_arg_node.const_name == 'Exception'
        end
      end
    end
  end
end
