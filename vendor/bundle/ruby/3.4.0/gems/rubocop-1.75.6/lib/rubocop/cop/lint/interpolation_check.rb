# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for interpolation in a single quoted string.
      #
      # @safety
      #   This cop's autocorrection is unsafe because although it always replaces single quotes as
      #   if it were miswritten double quotes, it is not always the case. For example,
      #   `'#{foo} bar'` would be replaced by `"#{foo} bar"`, so the replaced code would evaluate
      #   the expression `foo`.
      #
      # @example
      #
      #   # bad
      #   foo = 'something with #{interpolation} inside'
      #
      #   # good
      #   foo = "something with #{interpolation} inside"
      class InterpolationCheck < Base
        extend AutoCorrector

        MSG = 'Interpolation in single quoted string detected. ' \
              'Use double quoted strings if you need interpolation.'

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_str(node)
          return if node.parent&.regexp_type?
          return unless /(?<!\\)#\{.*\}/.match?(node.source)
          return if heredoc?(node)
          return unless node.loc.begin && node.loc.end
          return unless valid_syntax?(node)

          add_offense(node) { |corrector| autocorrect(corrector, node) }
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        private

        def autocorrect(corrector, node)
          starting_token, ending_token = if node.source.include?('"')
                                           ['%{', '}']
                                         else
                                           ['"', '"']
                                         end

          corrector.replace(node.loc.begin, starting_token)
          corrector.replace(node.loc.end, ending_token)
        end

        def heredoc?(node)
          node.loc.is_a?(Parser::Source::Map::Heredoc) || (node.parent && heredoc?(node.parent))
        end

        def valid_syntax?(node)
          double_quoted_string = node.source.gsub(/\A'|'\z/, '"')

          parse(double_quoted_string).valid_syntax?
        end
      end
    end
  end
end
