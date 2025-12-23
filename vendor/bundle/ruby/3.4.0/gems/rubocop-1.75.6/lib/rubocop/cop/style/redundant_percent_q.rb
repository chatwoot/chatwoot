# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usage of the %q/%Q syntax when '' or "" would do.
      #
      # @example
      #
      #   # bad
      #   name = %q(Bruce Wayne)
      #   time = %q(8 o'clock)
      #   question = %q("What did you say?")
      #
      #   # good
      #   name = 'Bruce Wayne'
      #   time = "8 o'clock"
      #   question = '"What did you say?"'
      #
      class RedundantPercentQ < Base
        extend AutoCorrector

        MSG = 'Use `%<q_type>s` only for strings that contain both ' \
              'single quotes and double quotes%<extra>s.'
        DYNAMIC_MSG = ', or for dynamic strings that contain double quotes'
        SINGLE_QUOTE = "'"
        QUOTE = '"'
        EMPTY = ''
        PERCENT_Q = '%q'
        PERCENT_CAPITAL_Q = '%Q'
        STRING_INTERPOLATION_REGEXP = /#\{.+\}/.freeze
        ESCAPED_NON_BACKSLASH = /\\[^\\]/.freeze

        def on_dstr(node)
          return unless string_literal?(node)

          check(node)
        end

        def on_str(node)
          # Interpolated strings that contain more than just interpolation
          # will call `on_dstr` for the entire string and `on_str` for the
          # non interpolated portion of the string
          return unless string_literal?(node)

          check(node)
        end

        private

        def check(node)
          return unless start_with_percent_q_variant?(node)
          return if interpolated_quotes?(node) || allowed_percent_q?(node)

          add_offense(node) do |corrector|
            delimiter = /\A%Q[^"]+\z|'/.match?(node.source) ? QUOTE : SINGLE_QUOTE

            corrector.replace(node.loc.begin, delimiter)
            corrector.replace(node.loc.end, delimiter)
          end
        end

        def interpolated_quotes?(node)
          node.source.include?(SINGLE_QUOTE) && node.source.include?(QUOTE)
        end

        def allowed_percent_q?(node)
          (node.source.start_with?(PERCENT_Q) && acceptable_q?(node)) ||
            (node.source.start_with?(PERCENT_CAPITAL_Q) && acceptable_capital_q?(node))
        end

        def message(node)
          src = node.source
          extra = if src.start_with?(PERCENT_CAPITAL_Q)
                    DYNAMIC_MSG
                  else
                    EMPTY
                  end
          format(MSG, q_type: src[0, 2], extra: extra)
        end

        def string_literal?(node)
          node.loc.respond_to?(:begin) && node.loc.respond_to?(:end) &&
            node.loc.begin && node.loc.end
        end

        def start_with_percent_q_variant?(string)
          string.source.start_with?(PERCENT_Q, PERCENT_CAPITAL_Q)
        end

        def acceptable_q?(node)
          src = node.source

          return true if STRING_INTERPOLATION_REGEXP.match?(src)

          src.scan(/\\./).any?(ESCAPED_NON_BACKSLASH)
        end

        def acceptable_capital_q?(node)
          src = node.source
          src.include?(QUOTE) &&
            (STRING_INTERPOLATION_REGEXP.match?(src) ||
            (node.str_type? && double_quotes_required?(src)))
        end
      end
    end
  end
end
