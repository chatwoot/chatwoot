# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that `exit` calls are not used within a rails app.
      # Valid options are instead to raise an error, break, return, or some
      # other form of stopping execution of current request.
      #
      # There are two obvious cases where `exit` is particularly harmful:
      #
      # * Usage in library code for your application. Even though Rails will
      # rescue from a `SystemExit` and continue on, unit testing that library
      # code will result in specs exiting (potentially silently if `exit(0)`
      # is used.)
      # * Usage in application code outside of the web process could result in
      # the program exiting, which could result in the code failing to run and
      # do its job.
      #
      # @example
      #   # bad
      #   exit(0)
      #
      #   # good
      #   raise 'a bad error has happened'
      class Exit < Base
        include ConfigurableEnforcedStyle

        MSG = 'Do not use `exit` in Rails applications.'
        RESTRICT_ON_SEND = %i[exit exit!].freeze
        EXPLICIT_RECEIVERS = %i[Kernel Process].freeze

        def on_send(node)
          add_offense(node.loc.selector) if offending_node?(node)
        end

        private

        def offending_node?(node)
          right_argument_count?(node.arguments) && right_receiver?(node.receiver)
        end

        # More than 1 argument likely means it is a different
        # `exit` implementation than the one we are preventing.
        def right_argument_count?(arg_nodes)
          arg_nodes.size <= 1
        end

        # Only register if exit is being called explicitly on `Kernel`,
        # `Process`, or if receiver node is nil for plain `exit` calls.
        def right_receiver?(receiver_node)
          return true unless receiver_node

          _a, receiver_node_class, _c = *receiver_node

          EXPLICIT_RECEIVERS.include?(receiver_node_class)
        end
      end
    end
  end
end
