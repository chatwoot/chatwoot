# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for using empty heredoc to reduce redundancy.
      #
      # @example
      #
      #   # bad
      #   <<~EOS
      #   EOS
      #
      #   <<-EOS
      #   EOS
      #
      #   <<EOS
      #   EOS
      #
      #   # good
      #   ''
      #
      #   # bad
      #   do_something(<<~EOS)
      #   EOS
      #
      #   do_something(<<-EOS)
      #   EOS
      #
      #   do_something(<<EOS)
      #   EOS
      #
      #   # good
      #   do_something('')
      #
      class EmptyHeredoc < Base
        include Heredoc
        include RangeHelp
        include StringLiteralsHelp
        extend AutoCorrector

        MSG = 'Use an empty string literal instead of heredoc.'

        def on_heredoc(node)
          heredoc_body = node.loc.heredoc_body

          return unless heredoc_body.source.empty?

          add_offense(node) do |corrector|
            heredoc_end = node.loc.heredoc_end

            corrector.replace(node, preferred_string_literal)
            corrector.remove(range_by_whole_lines(heredoc_body, include_final_newline: true))
            corrector.remove(range_by_whole_lines(heredoc_end, include_final_newline: true))
          end
        end
      end
    end
  end
end
