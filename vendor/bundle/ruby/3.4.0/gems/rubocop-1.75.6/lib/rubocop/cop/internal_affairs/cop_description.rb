# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the cop description to start with a word such as verb.
      #
      # @example
      #   # bad
      #   # This cop checks ....
      #   class SomeCop < Base
      #     ....
      #   end
      #
      #   # bad
      #   #
      #   # Checks ...
      #   class SomeCop < Base
      #     ...
      #   end
      #
      #   # good
      #   # Checks ...
      #   class SomeCop < Base
      #     ...
      #   end
      #
      class CopDescription < Base
        extend AutoCorrector

        MSG_STARTS_WITH_WRONG_WORD =
          'Description should be started with %<suggestion>s instead of `This cop ...`.'
        MSG_STARTS_WITH_EMPTY_COMMENT_LINE =
          'Description should not start with an empty comment line.'

        SPECIAL_WORDS = %w[is can could should will would must may].freeze
        COP_DESC_OFFENSE_REGEX =
          /^\s+# This cop (?<special>#{SPECIAL_WORDS.join('|')})?\s*(?<word>.+?) .*/.freeze
        REPLACEMENT_REGEX = /^\s+# This cop (#{SPECIAL_WORDS.join('|')})?\s*(.+?) /.freeze
        EMPTY_COMMENT_LINE_REGEX = /\A\s*#\s*\n\z/.freeze

        def on_class(node)
          return unless (module_node = node.parent) && node.parent_class

          description_beginning = first_comment_line(module_node)
          return unless description_beginning

          if description_beginning.match?(EMPTY_COMMENT_LINE_REGEX)
            register_offense_for_empty_comment_line(module_node, description_beginning)
          else
            start_with_subject = description_beginning.match(COP_DESC_OFFENSE_REGEX)
            return unless start_with_subject

            register_offense_for_wrong_word(module_node, description_beginning, start_with_subject)
          end
        end

        private

        def register_offense_for_empty_comment_line(module_node, description_beginning)
          range = range(module_node, description_beginning)
          add_offense(range, message: MSG_STARTS_WITH_EMPTY_COMMENT_LINE) do |corrector|
            corrector.remove(range)
          end
        end

        def register_offense_for_wrong_word(module_node, description_beginning, start_with_subject)
          suggestion = start_with_subject['word']&.capitalize
          range = range(module_node, description_beginning)
          suggestion_for_message = suggestion_for_message(suggestion, start_with_subject)
          message = format(MSG_STARTS_WITH_WRONG_WORD, suggestion: suggestion_for_message)

          add_offense(range, message: message) do |corrector|
            if suggestion && !start_with_subject['special']
              replace_with_suggestion(corrector, range, suggestion, description_beginning)
            end
          end
        end

        def replace_with_suggestion(corrector, range, suggestion, description_beginning)
          replacement = description_beginning.gsub(REPLACEMENT_REGEX, "#{suggestion} ")
          corrector.replace(range, replacement)
        end

        def range(node, comment_line)
          source_buffer = node.source_range.source_buffer

          begin_pos = node.source_range.begin_pos
          begin_pos += comment_index(node, comment_line)
          end_pos = begin_pos + comment_body(comment_line).length

          Parser::Source::Range.new(source_buffer, begin_pos, end_pos)
        end

        def suggestion_for_message(suggestion, match_data)
          if suggestion && !match_data['special']
            "`#{suggestion}`"
          else
            'a word such as verb'
          end
        end

        def first_comment_line(node)
          node.source.lines.find { |line| comment_line?(line) }
        end

        def comment_body(comment_line)
          comment_line.gsub(/^\s*# /, '')
        end

        def comment_index(node, comment_line)
          body = comment_body(comment_line)
          node.source.index(body)
        end
      end
    end
  end
end
