# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `split` argument can be replaced from
      # a deterministic regexp to a string.
      #
      # @example
      #   # bad
      #   'a,b,c'.split(/,/)
      #
      #   # good
      #   'a,b,c'.split(',')
      class RedundantSplitRegexpArgument < Base
        extend AutoCorrector

        MSG = 'Use string as argument instead of regexp.'
        RESTRICT_ON_SEND = %i[split].freeze
        DETERMINISTIC_REGEX = /\A(?:#{LITERAL_REGEX})+\Z/.freeze
        STR_SPECIAL_CHARS = %w[\n \" \' \\\\ \t \b \f \r].freeze

        def_node_matcher :split_call_with_regexp?, <<~PATTERN
          {(call !nil? :split $regexp)}
        PATTERN

        def on_send(node)
          return unless (regexp_node = split_call_with_regexp?(node))
          return if regexp_node.ignore_case? || regexp_node.content == ' '
          return unless determinist_regexp?(regexp_node)

          add_offense(regexp_node) do |corrector|
            new_argument = replacement(regexp_node)

            corrector.replace(regexp_node, "\"#{new_argument}\"")
          end
        end
        alias on_csend on_send

        private

        def determinist_regexp?(regexp_node)
          DETERMINISTIC_REGEX.match?(regexp_node.source)
        end

        def replacement(regexp_node)
          regexp_content = regexp_node.content
          stack = []
          chars = regexp_content.chars.each_with_object([]) do |char, strings|
            if stack.empty? && char == '\\'
              stack.push(char)
            else
              strings << "#{stack.pop}#{char}"
            end
          end
          chars.map do |char|
            char = char.dup
            char.delete!('\\') unless STR_SPECIAL_CHARS.include?(char)
            char
          end.join
        end
      end
    end
  end
end
