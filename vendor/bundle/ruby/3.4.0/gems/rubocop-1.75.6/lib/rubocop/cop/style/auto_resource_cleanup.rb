# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for cases when you could use a block
      # accepting version of a method that does automatic
      # resource cleanup.
      #
      # @example
      #
      #   # bad
      #   f = File.open('file')
      #
      #   # good
      #   File.open('file') do |f|
      #     # ...
      #   end
      #
      #   # bad
      #   f = Tempfile.open('temp')
      #
      #   # good
      #   Tempfile.open('temp') do |f|
      #     # ...
      #   end
      class AutoResourceCleanup < Base
        MSG = 'Use the block version of `%<current>s`.'
        RESTRICT_ON_SEND = %i[open].freeze

        # @!method file_open_method?(node)
        def_node_matcher :file_open_method?, <<~PATTERN
          (send (const {nil? cbase} {:File :Tempfile}) :open ...)
        PATTERN

        def on_send(node)
          return if !file_open_method?(node) || cleanup?(node)

          current = node.receiver.source_range.begin.join(node.selector.end).source

          add_offense(node, message: format(MSG, current: current))
        end

        private

        def cleanup?(node)
          return true if node.block_argument?
          return false unless (parent = node.parent)

          parent.block_type? || !parent.lvasgn_type?
        end
      end
    end
  end
end
