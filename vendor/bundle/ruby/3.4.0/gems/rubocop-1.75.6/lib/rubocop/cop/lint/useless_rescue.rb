# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for useless ``rescue``s, which only reraise rescued exceptions.
      #
      # @example
      #   # bad
      #   def foo
      #     do_something
      #   rescue
      #     raise
      #   end
      #
      #   # bad
      #   def foo
      #     do_something
      #   rescue => e
      #     raise # or 'raise e', or 'raise $!', or 'raise $ERROR_INFO'
      #   end
      #
      #   # good
      #   def foo
      #     do_something
      #   rescue
      #     do_cleanup
      #     raise
      #   end
      #
      #   # bad (latest rescue)
      #   def foo
      #     do_something
      #   rescue ArgumentError
      #     # noop
      #   rescue
      #     raise
      #   end
      #
      #   # good (not the latest rescue)
      #   def foo
      #     do_something
      #   rescue ArgumentError
      #     raise
      #   rescue
      #     # noop
      #   end
      #
      class UselessRescue < Base
        MSG = 'Useless `rescue` detected.'

        def on_rescue(node)
          resbody_node = node.resbody_branches.last
          add_offense(resbody_node) if only_reraising?(resbody_node)
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        def only_reraising?(resbody_node)
          return false if use_exception_variable_in_ensure?(resbody_node)

          body = resbody_node.body

          return false if body.nil? || !body.send_type? || !body.method?(:raise) || body.receiver
          return true unless body.arguments?
          return false if body.arguments.size > 1

          exception_name = body.first_argument.source

          exception_objects(resbody_node).include?(exception_name)
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

        def use_exception_variable_in_ensure?(resbody_node)
          return false unless (exception_variable = resbody_node.exception_variable)
          return false unless (ensure_node = resbody_node.each_ancestor(:ensure).first)
          return false unless (ensure_body = ensure_node.branch)

          ensure_body.each_descendant(:lvar).map(&:source).include?(exception_variable.source)
        end

        def exception_objects(resbody_node)
          [resbody_node.exception_variable&.source, '$!', '$ERROR_INFO']
        end
      end
    end
  end
end
