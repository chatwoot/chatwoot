# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of `processed_source.file_path` instead of `processed_source.buffer.name`.
      #
      # @example
      #
      #   # bad
      #   processed_source.buffer.name
      #
      #   # good
      #   processed_source.file_path
      #
      class ProcessedSourceBufferName < Base
        extend AutoCorrector

        MSG = 'Use `file_path` instead.'

        RESTRICT_ON_SEND = %i[name].freeze

        # @!method processed_source_buffer_name?(node)
        def_node_matcher :processed_source_buffer_name?, <<~PATTERN
          (send
            (send
              {(lvar :processed_source) (send nil? :processed_source)} :buffer) :name)
        PATTERN

        def on_send(node)
          return unless processed_source_buffer_name?(node)

          offense_range = node.children.first.loc.selector.begin.join(node.source_range.end)

          add_offense(offense_range) do |corrector|
            corrector.replace(offense_range, 'file_path')
          end
        end
      end
    end
  end
end
