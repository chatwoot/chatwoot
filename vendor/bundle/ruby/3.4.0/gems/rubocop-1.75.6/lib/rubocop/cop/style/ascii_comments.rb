# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for non-ascii (non-English) characters
      # in comments. You could set an array of allowed non-ascii chars in
      # `AllowedChars` attribute (copyright notice "©" by default).
      #
      # @example
      #   # bad
      #   # Translates from English to 日本語。
      #
      #   # good
      #   # Translates from English to Japanese
      class AsciiComments < Base
        include RangeHelp

        MSG = 'Use only ascii symbols in comments.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if comment.text.ascii_only?
            next if only_allowed_non_ascii_chars?(comment.text)

            add_offense(first_offense_range(comment))
          end
        end

        private

        def first_offense_range(comment)
          expression    = comment.source_range
          first_offense = first_non_ascii_chars(comment.text)

          start_position = expression.begin_pos + comment.text.index(first_offense)
          end_position   = start_position + first_offense.length

          range_between(start_position, end_position)
        end

        def first_non_ascii_chars(string)
          string.match(/[^[:ascii:]]+/).to_s
        end

        def only_allowed_non_ascii_chars?(string)
          non_ascii = string.scan(/[^[:ascii:]]/)
          (non_ascii - allowed_non_ascii_chars).empty?
        end

        def allowed_non_ascii_chars
          cop_config['AllowedChars'] || []
        end
      end
    end
  end
end
