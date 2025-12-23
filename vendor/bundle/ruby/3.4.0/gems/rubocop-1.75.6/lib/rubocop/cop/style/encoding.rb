# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks ensures source files have no utf-8 encoding comments.
      # @example
      #   # bad
      #   # encoding: UTF-8
      #   # coding: UTF-8
      #   # -*- coding: UTF-8 -*-
      class Encoding < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Unnecessary utf-8 encoding comment.'
        ENCODING_PATTERN = /#.*coding\s?[:=]\s?(?:UTF|utf)-8/.freeze
        SHEBANG = '#!'

        def on_new_investigation
          return if processed_source.buffer.source.empty?

          comments.each do |line_number, comment|
            next unless offense?(comment)

            register_offense(line_number, comment)
          end
        end

        private

        def comments
          processed_source.lines.each.with_index.with_object({}) do |(line, line_number), comments|
            next if line.start_with?(SHEBANG)

            comment = MagicComment.parse(line)
            return comments unless comment.valid?

            comments[line_number + 1] = comment
          end
        end

        def offense?(comment)
          comment.encoding_specified? && comment.encoding.casecmp('utf-8').zero?
        end

        def register_offense(line_number, comment)
          range = processed_source.buffer.line_range(line_number)

          add_offense(range) do |corrector|
            text = comment.without(:encoding)

            if text.blank?
              corrector.remove(range_with_surrounding_space(range, side: :right))
            else
              corrector.replace(range, text)
            end
          end
        end
      end
    end
  end
end
