# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for excessive whitespace in example descriptions.
      #
      # @example
      #   # bad
      #   it '  has  excessive   spacing  ' do
      #   end
      #
      #   # good
      #   it 'has excessive spacing' do
      #   end
      #
      # @example
      #   # bad
      #   context '  when a condition   is met  ' do
      #   end
      #
      #   # good
      #   context 'when a condition is met' do
      #   end
      #
      class ExcessiveDocstringSpacing < Base
        extend AutoCorrector

        MSG = 'Excessive whitespace.'

        # @!method example_description(node)
        def_node_matcher :example_description, <<~PATTERN
          (send _ {#Examples.all #ExampleGroups.all} ${
            $str
            $(dstr ({str dstr `sym} ...) ...)
          } ...)
        PATTERN

        def on_send(node)
          example_description(node) do |description_node, message|
            return if description_node.heredoc?

            text = text(message)

            return unless excessive_whitespace?(text)

            add_whitespace_offense(description_node, text)
          end
        end

        private

        # @param text [String]
        def excessive_whitespace?(text)
          text.match?(/
            # Leading space
            \A[[:blank:]]
            |
            # Trailing space
            [[:blank:]]\z
            |
            # Two or more consecutive spaces, except if they are leading spaces
            [^[[:space:]]][[:blank:]]{2,}[^[[:blank:]]]
          /x)
        end

        # @param text [String]
        def strip_excessive_whitespace(text)
          text
            .gsub(/[[:blank:]]{2,}/, ' ')
            .gsub(/\A[[:blank:]]|[[:blank:]]\z/, '')
        end

        # @param node [RuboCop::AST::Node]
        # @param text [String]
        def add_whitespace_offense(node, text)
          docstring = docstring(node)
          corrected = strip_excessive_whitespace(text)

          add_offense(docstring) do |corrector|
            corrector.replace(docstring, corrected)
          end
        end

        def docstring(node)
          expr = node.source_range

          Parser::Source::Range.new(
            expr.source_buffer,
            expr.begin_pos + 1,
            expr.end_pos - 1
          )
        end

        # Recursive processing is required to process nested dstr nodes
        # that is the case for \-separated multiline strings with interpolation.
        def text(node)
          case node.type
          when :dstr
            node.node_parts.map { |child_node| text(child_node) }.join
          when :str, :sym
            node.value
          else
            node.source
          end
        end
      end
    end
  end
end
