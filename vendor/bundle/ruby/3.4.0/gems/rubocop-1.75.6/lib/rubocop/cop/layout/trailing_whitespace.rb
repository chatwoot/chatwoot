# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Looks for trailing whitespace in the source code.
      #
      # @example
      #   # The line in this example contains spaces after the 0.
      #   # bad
      #   x = 0
      #
      #   # The line in this example ends directly after the 0.
      #   # good
      #   x = 0
      #
      # @example AllowInHeredoc: false (default)
      #   # The line in this example contains spaces after the 0.
      #   # bad
      #   code = <<~RUBY
      #     x = 0
      #   RUBY
      #
      #   # ok
      #   code = <<~RUBY
      #     x = 0 #{}
      #   RUBY
      #
      #   # good
      #   trailing_whitespace = ' '
      #   code = <<~RUBY
      #     x = 0#{trailing_whitespace}
      #   RUBY
      #
      # @example AllowInHeredoc: true
      #   # The line in this example contains spaces after the 0.
      #   # good
      #   code = <<~RUBY
      #     x = 0
      #   RUBY
      #
      class TrailingWhitespace < Base
        include RangeHelp
        include Heredoc
        extend AutoCorrector

        MSG = 'Trailing whitespace detected.'

        def on_new_investigation
          processed_source.lines.each_with_index do |line, index|
            next unless line.match?(/[[:blank:]]\z/)

            process_line(line, index + 1)
          end
        end

        def on_heredoc(_node); end

        private

        def process_line(line, lineno)
          heredoc = find_heredoc(lineno)
          return if skip_heredoc? && heredoc

          range = offense_range(lineno, line)
          add_offense(range) do |corrector|
            if heredoc
              process_line_in_heredoc(corrector, range, heredoc)
            else
              corrector.remove(range)
            end
          end
        end

        def process_line_in_heredoc(corrector, range, heredoc)
          indent_level = indent_level(find_heredoc(range.line).loc.heredoc_body.source)
          whitespace_only = whitespace_only?(range)
          if whitespace_only && whitespace_is_indentation?(range, indent_level)
            corrector.remove(range)
          elsif !static?(heredoc)
            range = range_between(range.begin_pos + indent_level, range.end_pos) if whitespace_only
            corrector.wrap(range, "\#{'", "'}")
          end
        end

        def whitespace_is_indentation?(range, level)
          range.source[/[[:blank:]]+/].length <= level
        end

        def whitespace_only?(range)
          source = range_with_surrounding_space(range).source
          source.start_with?("\n") && source.end_with?("\n")
        end

        def static?(heredoc)
          heredoc.source.end_with? "'"
        end

        def skip_heredoc?
          cop_config.fetch('AllowInHeredoc', false)
        end

        def find_heredoc(line_number)
          heredocs.each { |node, r| return node if r.include?(line_number) }
          nil
        end

        def heredocs
          @heredocs ||= extract_heredocs(processed_source.ast)
        end

        def extract_heredocs(ast)
          return [] unless ast

          heredocs = []
          ast.each_node(:str, :dstr, :xstr) do |node|
            next unless node.heredoc?

            body = node.location.heredoc_body
            heredocs << [node, body.first_line...body.last_line]
          end
          heredocs
        end

        def offense_range(lineno, line)
          source_range(
            processed_source.buffer, lineno, (line.sub(/[[:blank:]]+\z/, '').length)...(line.length)
          )
        end
      end
    end
  end
end
