# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for unnecessary leading blank lines at the beginning
      # of a file.
      #
      # @example
      #
      #   # bad
      #   # (start of file)
      #
      #   class Foo
      #   end
      #
      #   # bad
      #   # (start of file)
      #
      #   # a comment
      #
      #   # good
      #   # (start of file)
      #   class Foo
      #   end
      #
      #   # good
      #   # (start of file)
      #   # a comment
      class LeadingEmptyLines < Base
        extend AutoCorrector

        MSG = 'Unnecessary blank line at the beginning of the source.'

        def on_new_investigation
          token = processed_source.tokens[0]
          return unless token && token.line > 1

          add_offense(token.pos) do |corrector|
            range = Parser::Source::Range.new(processed_source.buffer, 0, token.begin_pos)

            corrector.remove(range)
          end
        end
      end
    end
  end
end
