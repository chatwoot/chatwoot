# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `IO.select` that is incompatible with Fiber Scheduler since Ruby 3.0.
      #
      # When an array of IO objects waiting for an exception (the third argument of `IO.select`)
      # is used as an argument, there is no alternative API, so offenses are not registered.
      #
      # NOTE: When the method is successful the return value of `IO.select` is `[[IO]]`,
      # and the return value of `io.wait_readable` and `io.wait_writable` are `self`.
      # They are not autocorrected when assigning a return value because these types are different.
      # It's up to user how to handle the return value.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `NoMethodError` occurs
      #   if `require 'io/wait'` is not called.
      #
      # @example
      #
      #   # bad
      #   IO.select([io], [], [], timeout)
      #
      #   # good
      #   io.wait_readable(timeout)
      #
      #   # bad
      #   IO.select([], [io], [], timeout)
      #
      #   # good
      #   io.wait_writable(timeout)
      #
      class IncompatibleIoSelectWithFiberScheduler < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[select].freeze

        # @!method io_select(node)
        def_node_matcher :io_select, <<~PATTERN
          (send
            (const {nil? cbase} :IO) :select $...)
        PATTERN

        def on_send(node)
          read, write, excepts, timeout = *io_select(node)
          return if excepts && !excepts.children.empty?
          return unless scheduler_compatible?(read, write) || scheduler_compatible?(write, read)

          preferred = preferred_method(read, write, timeout)
          message = format(MSG, preferred: preferred, current: node.source)

          add_offense(node, message: message) do |corrector|
            next if node.parent&.assignment?

            corrector.replace(node, preferred)
          end
        end

        private

        def scheduler_compatible?(io1, io2)
          return false unless io1&.array_type? && io1.values.size == 1

          io2&.array_type? ? io2.values.empty? : (io2.nil? || io2.nil_type?)
        end

        def preferred_method(read, write, timeout)
          timeout_argument = timeout.nil? ? '' : "(#{timeout.source})"

          if read.array_type? && read.values[0]
            "#{read.values[0].source}.wait_readable#{timeout_argument}"
          else
            "#{write.values[0].source}.wait_writable#{timeout_argument}"
          end
        end
      end
    end
  end
end
