# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Helps you transition from mutable string literals
      # to frozen string literals.
      # It will add the `# frozen_string_literal: true` magic comment to the top
      # of files to enable frozen string literals. Frozen string literals may be
      # default in future Ruby. The comment will be added below a shebang and
      # encoding comment. The frozen string literal comment is only valid in Ruby 2.3+.
      #
      # Note that the cop will accept files where the comment exists but is set
      # to `false` instead of `true`.
      #
      # To require a blank line after this comment, please see
      # `Layout/EmptyLineAfterMagicComment` cop.
      #
      # @safety
      #  This cop's autocorrection is unsafe since any strings mutations will
      #  change from being accepted to raising `FrozenError`, as all strings
      #  will become frozen by default, and will need to be manually refactored.
      #
      # @example EnforcedStyle: always (default)
      #   # The `always` style will always add the frozen string literal comment
      #   # to a file, regardless of the Ruby version or if `freeze` or `<<` are
      #   # called on a string literal.
      #   # bad
      #   module Bar
      #     # ...
      #   end
      #
      #   # good
      #   # frozen_string_literal: true
      #
      #   module Bar
      #     # ...
      #   end
      #
      #   # good
      #   # frozen_string_literal: false
      #
      #   module Bar
      #     # ...
      #   end
      #
      # @example EnforcedStyle: never
      #   # The `never` will enforce that the frozen string literal comment does
      #   # not exist in a file.
      #   # bad
      #   # frozen_string_literal: true
      #
      #   module Baz
      #     # ...
      #   end
      #
      #   # good
      #   module Baz
      #     # ...
      #   end
      #
      # @example EnforcedStyle: always_true
      #   # The `always_true` style enforces that the frozen string literal
      #   # comment is set to `true`. This is a stricter option than `always`
      #   # and forces projects to use frozen string literals.
      #   # bad
      #   # frozen_string_literal: false
      #
      #   module Baz
      #     # ...
      #   end
      #
      #   # bad
      #   module Baz
      #     # ...
      #   end
      #
      #   # good
      #   # frozen_string_literal: true
      #
      #   module Bar
      #     # ...
      #   end
      class FrozenStringLiteralComment < Base
        include ConfigurableEnforcedStyle
        include FrozenStringLiteral
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.3

        MSG_MISSING_TRUE = 'Missing magic comment `# frozen_string_literal: true`.'
        MSG_MISSING = 'Missing frozen string literal comment.'
        MSG_UNNECESSARY = 'Unnecessary frozen string literal comment.'
        MSG_DISABLED = 'Frozen string literal comment must be set to `true`.'
        SHEBANG = '#!'

        def on_new_investigation
          return if processed_source.tokens.empty?

          case style
          when :never
            ensure_no_comment(processed_source)
          when :always_true
            ensure_enabled_comment(processed_source)
          else
            ensure_comment(processed_source)
          end
        end

        private

        def ensure_no_comment(processed_source)
          return unless frozen_string_literal_comment_exists?

          unnecessary_comment_offense(processed_source)
        end

        def ensure_comment(processed_source)
          return if frozen_string_literal_comment_exists?

          missing_offense(processed_source)
        end

        def ensure_enabled_comment(processed_source)
          if frozen_string_literal_specified?
            return if frozen_string_literals_enabled?

            # The comment exists, but is not enabled.
            disabled_offense(processed_source)
          else # The comment doesn't exist at all.
            missing_true_offense(processed_source)
          end
        end

        def last_special_comment(processed_source)
          token_number = 0
          if processed_source.tokens[token_number].text.start_with?(SHEBANG)
            token = processed_source.tokens[token_number]
            token_number += 1
          end

          next_token = processed_source.tokens[token_number]
          if next_token&.text&.valid_encoding? && Encoding::ENCODING_PATTERN.match?(next_token.text)
            token = next_token
          end

          token
        end

        def frozen_string_literal_comment(processed_source)
          processed_source.tokens.find do |token|
            MagicComment.parse(token.text).frozen_string_literal_specified?
          end
        end

        def missing_offense(processed_source)
          range = source_range(processed_source.buffer, 0, 0)

          add_offense(range, message: MSG_MISSING) { |corrector| insert_comment(corrector) }
        end

        def missing_true_offense(processed_source)
          range = source_range(processed_source.buffer, 0, 0)

          add_offense(range, message: MSG_MISSING_TRUE) { |corrector| insert_comment(corrector) }
        end

        def unnecessary_comment_offense(processed_source)
          frozen_string_literal_comment = frozen_string_literal_comment(processed_source)

          add_offense(frozen_string_literal_comment.pos, message: MSG_UNNECESSARY) do |corrector|
            remove_comment(corrector, frozen_string_literal_comment)
          end
        end

        def disabled_offense(processed_source)
          frozen_string_literal_comment = frozen_string_literal_comment(processed_source)

          add_offense(frozen_string_literal_comment.pos, message: MSG_DISABLED) do |corrector|
            enable_comment(corrector)
          end
        end

        def remove_comment(corrector, node)
          corrector.remove(range_with_surrounding_space(node.pos, side: :right))
        end

        def enable_comment(corrector)
          comment = frozen_string_literal_comment(processed_source)
          replacement = MagicComment.parse(comment.text).new_frozen_string_literal(true)

          corrector.replace(line_range(comment.line), replacement)
        end

        def insert_comment(corrector)
          comment = last_special_comment(processed_source)

          if comment
            corrector.insert_after(line_range(comment.line), following_comment)
          else
            corrector.insert_before(processed_source.buffer.source_range, preceding_comment)
          end
        end

        def line_range(line)
          processed_source.buffer.line_range(line)
        end

        def preceding_comment
          "#{FROZEN_STRING_LITERAL_ENABLED}\n"
        end

        def following_comment
          "\n#{FROZEN_STRING_LITERAL_ENABLED}"
        end
      end
    end
  end
end
