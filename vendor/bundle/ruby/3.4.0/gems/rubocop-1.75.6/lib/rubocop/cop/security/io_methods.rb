# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the first argument to `IO.read`, `IO.binread`, `IO.write`, `IO.binwrite`,
      # `IO.foreach`, and `IO.readlines`.
      #
      # If argument starts with a pipe character (`'|'`) and the receiver is the `IO` class,
      # a subprocess is created in the same way as `Kernel#open`, and its output is returned.
      # `Kernel#open` may allow unintentional command injection, which is the reason these
      # `IO` methods are a security risk.
      # Consider to use `File.read` to disable the behavior of subprocess invocation.
      #
      # @safety
      #   This cop is unsafe because false positive will occur if the variable passed as
      #   the first argument is a command that is not a file path.
      #
      # @example
      #
      #   # bad
      #   IO.read(path)
      #   IO.read('path')
      #
      #   # good
      #   File.read(path)
      #   File.read('path')
      #   IO.read('| command') # Allow intentional command invocation.
      #
      class IoMethods < Base
        extend AutoCorrector

        MSG = '`File.%<method_name>s` is safer than `IO.%<method_name>s`.'
        RESTRICT_ON_SEND = %i[read binread write binwrite foreach readlines].freeze

        def on_send(node)
          return unless (receiver = node.receiver) && receiver.source == 'IO'

          argument = node.first_argument
          return if argument.respond_to?(:value) && argument.value.strip.start_with?('|')

          add_offense(node, message: format(MSG, method_name: node.method_name)) do |corrector|
            corrector.replace(receiver, 'File')
          end
        end
      end
    end
  end
end
