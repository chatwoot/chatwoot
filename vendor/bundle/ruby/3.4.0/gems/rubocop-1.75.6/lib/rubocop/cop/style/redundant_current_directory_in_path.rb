# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for paths given to `require_relative` that start with
      # the current directory (`./`), which can be omitted.
      #
      # @example
      #
      #   # bad
      #   require_relative './path/to/feature'
      #
      #   # good
      #   require_relative 'path/to/feature'
      #
      class RedundantCurrentDirectoryInPath < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the redundant current directory path.'
        RESTRICT_ON_SEND = %i[require_relative].freeze
        CURRENT_DIRECTORY_PREFIX = %r{\./+}.freeze
        REDUNDANT_CURRENT_DIRECTORY_PREFIX = /\A#{CURRENT_DIRECTORY_PREFIX}/.freeze

        def on_send(node)
          return unless (first_argument = node.first_argument)
          return unless (index = first_argument.source.index(CURRENT_DIRECTORY_PREFIX))
          return unless (redundant_length = redundant_path_length(first_argument.str_content))

          begin_pos = first_argument.source_range.begin.begin_pos + index
          end_pos = begin_pos + redundant_length
          range = range_between(begin_pos, end_pos)

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end

        private

        def redundant_path_length(path)
          return unless (match = path&.match(REDUNDANT_CURRENT_DIRECTORY_PREFIX))

          match[0].length
        end
      end
    end
  end
end
