# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks that your heredocs are using the configured case.
      # By default it is configured to enforce uppercase heredocs.
      #
      # @example EnforcedStyle: uppercase (default)
      #   # bad
      #   <<-sql
      #     SELECT * FROM foo
      #   sql
      #
      #   # good
      #   <<-SQL
      #     SELECT * FROM foo
      #   SQL
      #
      # @example EnforcedStyle: lowercase
      #   # bad
      #   <<-SQL
      #     SELECT * FROM foo
      #   SQL
      #
      #   # good
      #   <<-sql
      #     SELECT * FROM foo
      #   sql
      class HeredocDelimiterCase < Base
        include Heredoc
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use %<style>s heredoc delimiters.'

        def on_heredoc(node)
          return if correct_case_delimiters?(node)

          add_offense(node.loc.heredoc_end) do |corrector|
            expr = node.source_range

            corrector.replace(expr, correct_delimiters(expr.source))
            corrector.replace(node.loc.heredoc_end, correct_delimiters(delimiter_string(expr)))
          end
        end

        private

        def message(_node)
          format(MSG, style: style)
        end

        def correct_case_delimiters?(node)
          delimiter_string(node) == correct_delimiters(delimiter_string(node))
        end

        def correct_delimiters(source)
          if style == :uppercase
            source.upcase
          else
            source.downcase
          end
        end
      end
    end
  end
end
