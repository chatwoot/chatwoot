# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks that quotes inside string, symbol, and regexp interpolations
      # match the configured preference.
      #
      # @example EnforcedStyle: single_quotes (default)
      #   # bad
      #   string = "Tests #{success ? "PASS" : "FAIL"}"
      #   symbol = :"Tests #{success ? "PASS" : "FAIL"}"
      #   heredoc = <<~TEXT
      #     Tests #{success ? "PASS" : "FAIL"}
      #   TEXT
      #   regexp = /Tests #{success ? "PASS" : "FAIL"}/
      #
      #   # good
      #   string = "Tests #{success ? 'PASS' : 'FAIL'}"
      #   symbol = :"Tests #{success ? 'PASS' : 'FAIL'}"
      #   heredoc = <<~TEXT
      #     Tests #{success ? 'PASS' : 'FAIL'}
      #   TEXT
      #   regexp = /Tests #{success ? 'PASS' : 'FAIL'}/
      #
      # @example EnforcedStyle: double_quotes
      #   # bad
      #   string = "Tests #{success ? 'PASS' : 'FAIL'}"
      #   symbol = :"Tests #{success ? 'PASS' : 'FAIL'}"
      #   heredoc = <<~TEXT
      #     Tests #{success ? 'PASS' : 'FAIL'}
      #   TEXT
      #   regexp = /Tests #{success ? 'PASS' : 'FAIL'}/
      #
      #   # good
      #   string = "Tests #{success ? "PASS" : "FAIL"}"
      #   symbol = :"Tests #{success ? "PASS" : "FAIL"}"
      #   heredoc = <<~TEXT
      #     Tests #{success ? "PASS" : "FAIL"}
      #   TEXT
      #   regexp = /Tests #{success ? "PASS" : "FAIL"}/
      class StringLiteralsInInterpolation < Base
        include ConfigurableEnforcedStyle
        include StringLiteralsHelp
        include StringHelp
        extend AutoCorrector

        def autocorrect(corrector, node)
          StringLiteralCorrector.correct(corrector, node, style)
        end

        # Cop classes that include the StringHelp module usually ignore regexp
        # nodes. Not so for this cop, which is why we override the on_regexp
        # definition with an empty one.
        def on_regexp(node); end

        private

        def message(_node)
          # single_quotes -> single-quoted
          kind = style.to_s.sub(/_(.*)s/, '-\1d')

          "Prefer #{kind} strings inside interpolations."
        end

        def offense?(node)
          # If it's not a string within an interpolation, then it's not an
          # offense for this cop.
          return false unless inside_interpolation?(node)

          wrong_quotes?(node)
        end
      end
    end
  end
end
