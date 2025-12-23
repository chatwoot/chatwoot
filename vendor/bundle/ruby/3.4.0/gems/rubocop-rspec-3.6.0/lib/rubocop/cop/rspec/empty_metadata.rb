# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Avoid empty metadata hash.
      #
      # @example EnforcedStyle: symbol (default)
      #   # bad
      #   describe 'Something', {}
      #
      #   # good
      #   describe 'Something'
      class EmptyMetadata < Base
        extend AutoCorrector

        include Metadata
        include RangeHelp

        MSG = 'Avoid empty metadata hash.'

        def on_metadata(_symbols, hash)
          return unless hash&.pairs&.empty?
          return if hash.children.any?(&:kwsplat_type?)

          add_offense(hash) do |corrector|
            remove_empty_metadata(corrector, hash)
          end
        end

        private

        def remove_empty_metadata(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end
      end
    end
  end
end
