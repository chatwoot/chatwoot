# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant heredoc delimiter quotes.
      #
      # @example
      #
      #   # bad
      #   do_something(<<~'EOS')
      #     no string interpolation style text
      #   EOS
      #
      #   # good
      #   do_something(<<~EOS)
      #     no string interpolation style text
      #   EOS
      #
      #   do_something(<<~'EOS')
      #     #{string_interpolation_style_text_not_evaluated}
      #   EOS
      #
      #   do_something(<<~'EOS')
      #     Preserve \
      #     newlines
      #   EOS
      #
      class RedundantHeredocDelimiterQuotes < Base
        include Heredoc
        extend AutoCorrector

        MSG = 'Remove the redundant heredoc delimiter quotes, use `%<replacement>s` instead.'
        STRING_INTERPOLATION_OR_ESCAPED_CHARACTER_PATTERN = /#(\{|@|\$)|\\/.freeze

        def on_heredoc(node)
          return if need_heredoc_delimiter_quotes?(node)

          replacement = "#{heredoc_type(node)}#{delimiter_string(node)}"

          add_offense(node, message: format(MSG, replacement: replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        private

        def need_heredoc_delimiter_quotes?(node)
          heredoc_delimiter = node.source.delete(heredoc_type(node))
          return true unless heredoc_delimiter.start_with?("'", '"')

          node.loc.heredoc_end.source.strip.match?(/\W/) ||
            node.loc.heredoc_body.source.match?(STRING_INTERPOLATION_OR_ESCAPED_CHARACTER_PATTERN)
        end
      end
    end
  end
end
