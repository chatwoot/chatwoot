# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the here document bodies. The bodies
      # are indented one step.
      #
      # NOTE: When ``Layout/LineLength``'s `AllowHeredoc` is false (not default),
      #       this cop does not add any offenses for long here documents to
      #       avoid ``Layout/LineLength``'s offenses.
      #
      # @example
      #   # bad
      #   <<-RUBY
      #   something
      #   RUBY
      #
      #   # good
      #   <<~RUBY
      #     something
      #   RUBY
      #
      class HeredocIndentation < Base
        include Alignment
        include Heredoc
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.3

        TYPE_MSG = 'Use %<indentation_width>d spaces for indentation in a ' \
                   'heredoc by using `<<~` instead of `%<current_indent_type>s`.'
        WIDTH_MSG = 'Use %<indentation_width>d spaces for indentation in a heredoc.'

        def on_heredoc(node)
          body = heredoc_body(node)
          return if body.strip.empty?

          body_indent_level = indent_level(body)
          heredoc_indent_type = heredoc_indent_type(node)

          if heredoc_indent_type == '~'
            expected_indent_level = base_indent_level(node) + configured_indentation_width
            return if expected_indent_level == body_indent_level
          else
            return unless body_indent_level.zero?
          end

          return if line_too_long?(node)

          register_offense(node, heredoc_indent_type)
        end

        private

        def register_offense(node, heredoc_indent_type)
          message = message(heredoc_indent_type)

          add_offense(node.loc.heredoc_body, message: message) do |corrector|
            if heredoc_indent_type == '~'
              adjust_squiggly(corrector, node)
            else
              adjust_minus(corrector, node)
            end
          end
        end

        def message(heredoc_indent_type)
          current_indent_type = "<<#{heredoc_indent_type}"

          if current_indent_type == '<<~'
            width_message(configured_indentation_width)
          else
            type_message(configured_indentation_width, current_indent_type)
          end
        end

        def type_message(indentation_width, current_indent_type)
          format(
            TYPE_MSG,
            indentation_width: indentation_width,
            current_indent_type: current_indent_type
          )
        end

        def width_message(indentation_width)
          format(WIDTH_MSG, indentation_width: indentation_width)
        end

        def line_too_long?(node)
          return false if unlimited_heredoc_length?

          body = heredoc_body(node)

          expected_indent = base_indent_level(node) + configured_indentation_width
          actual_indent = indent_level(body)
          increase_indent_level = expected_indent - actual_indent

          longest_line(body).size + increase_indent_level >= max_line_length
        end

        def longest_line(lines)
          lines.each_line.max_by { |line| line.chomp.size }.chomp
        end

        def unlimited_heredoc_length?
          config.for_cop('Layout/LineLength')['AllowHeredoc']
        end

        def max_line_length
          config.for_cop('Layout/LineLength')['Max']
        end

        def adjust_squiggly(corrector, node)
          corrector.replace(node.loc.heredoc_body, indented_body(node))
          corrector.replace(node.loc.heredoc_end, indented_end(node))
        end

        def adjust_minus(corrector, node)
          heredoc_beginning = node.source
          corrected = heredoc_beginning.sub(/<<-?/, '<<~')
          corrector.replace(node, corrected)
        end

        def indented_body(node)
          body = heredoc_body(node)
          body_indent_level = indent_level(body)
          correct_indent_level = base_indent_level(node) + configured_indentation_width
          body.gsub(/^[^\S\r\n]{#{body_indent_level}}/, ' ' * correct_indent_level)
        end

        def indented_end(node)
          end_ = heredoc_end(node)
          end_indent_level = indent_level(end_)
          correct_indent_level = base_indent_level(node)
          if end_indent_level < correct_indent_level
            end_.gsub(/^\s{#{end_indent_level}}/, ' ' * correct_indent_level)
          else
            end_
          end
        end

        def base_indent_level(node)
          base_line_num = node.source_range.line
          base_line = processed_source.lines[base_line_num - 1]
          indent_level(base_line)
        end

        # Returns '~', '-' or nil
        def heredoc_indent_type(node)
          node.source[/^<<([~-])/, 1]
        end

        def heredoc_body(node)
          node.loc.heredoc_body.source
        end

        def heredoc_end(node)
          node.loc.heredoc_end.source
        end
      end
    end
  end
end
