# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Common functionality for checking if presence/absence of empty lines
      # around some kind of body matches the configuration.
      module EmptyLinesAroundBody
        extend NodePattern::Macros
        include ConfigurableEnforcedStyle
        include RangeHelp

        MSG_EXTRA = 'Extra empty line detected at %<kind>s body %<location>s.'
        MSG_MISSING = 'Empty line missing at %<kind>s body %<location>s.'
        MSG_DEFERRED = 'Empty line missing before first %<type>s definition'

        private

        # @!method constant_definition?(node)
        def_node_matcher :constant_definition?, '{class module}'

        # @!method empty_line_required?(node)
        def_node_matcher :empty_line_required?,
                         '{any_def class module (send nil? {:private :protected :public})}'

        def check(node, body, adjusted_first_line: nil)
          return if valid_body_style?(body)
          return if node.single_line?

          first_line = adjusted_first_line || node.source_range.first_line
          last_line = node.source_range.last_line

          case style
          when :empty_lines_except_namespace
            check_empty_lines_except_namespace(body, first_line, last_line)
          when :empty_lines_special
            check_empty_lines_special(body, first_line, last_line)
          else
            check_both(style, first_line, last_line)
          end
        end

        def check_empty_lines_except_namespace(body, first_line, last_line)
          if namespace?(body, with_one_child: true)
            check_both(:no_empty_lines, first_line, last_line)
          else
            check_both(:empty_lines, first_line, last_line)
          end
        end

        def check_empty_lines_special(body, first_line, last_line)
          return unless body

          if namespace?(body, with_one_child: true)
            check_both(:no_empty_lines, first_line, last_line)
          else
            if first_child_requires_empty_line?(body)
              check_beginning(:empty_lines, first_line)
            else
              check_beginning(:no_empty_lines, first_line)
              check_deferred_empty_line(body)
            end
            check_ending(:empty_lines, last_line)
          end
        end

        def check_both(style, first_line, last_line)
          case style
          when :beginning_only
            check_beginning(:empty_lines, first_line)
            check_ending(:no_empty_lines, last_line)
          when :ending_only
            check_beginning(:no_empty_lines, first_line)
            check_ending(:empty_lines, last_line)
          else
            check_beginning(style, first_line)
            check_ending(style, last_line)
          end
        end

        def check_beginning(style, first_line)
          check_source(style, first_line, 'beginning')
        end

        def check_ending(style, last_line)
          check_source(style, last_line - 2, 'end')
        end

        def check_source(style, line_no, desc)
          case style
          when :no_empty_lines
            check_line(style, line_no, message(MSG_EXTRA, desc), &:empty?)
          when :empty_lines
            check_line(style, line_no, message(MSG_MISSING, desc)) { |line| !line.empty? }
          end
        end

        def check_line(style, line, msg)
          return unless yield(processed_source.lines[line])

          offset = style == :empty_lines && msg.include?('end.') ? 2 : 1
          range = source_range(processed_source.buffer, line + offset, 0)
          add_offense(range, message: msg) do |corrector|
            EmptyLineCorrector.correct(corrector, [style, range])
          end
        end

        def check_deferred_empty_line(body)
          node = first_empty_line_required_child(body)
          return unless node

          line = previous_line_ignoring_comments(node.first_line)
          return if processed_source[line].empty?

          range = source_range(processed_source.buffer, line + 2, 0)

          add_offense(range, message: deferred_message(node)) do |corrector|
            EmptyLineCorrector.correct(corrector, [:empty_lines, range])
          end
        end

        def namespace?(body, with_one_child: false)
          if body.begin_type?
            return false if with_one_child

            body.children.all? { |child| constant_definition?(child) }
          else
            constant_definition?(body)
          end
        end

        def first_child_requires_empty_line?(body)
          if body.begin_type?
            empty_line_required?(body.children.first)
          else
            empty_line_required?(body)
          end
        end

        def first_empty_line_required_child(body)
          if body.begin_type?
            body.children.find { |child| empty_line_required?(child) }
          elsif empty_line_required?(body)
            body
          end
        end

        def previous_line_ignoring_comments(send_line)
          (send_line - 2).downto(0) do |line|
            return line unless comment_line?(processed_source[line])
          end
          0
        end

        def message(type, desc)
          format(type, kind: self.class::KIND, location: desc)
        end

        def deferred_message(node)
          format(MSG_DEFERRED, type: node.type)
        end

        def valid_body_style?(body)
          # When style is `empty_lines`, if the body is empty, we don't enforce
          # the presence OR absence of an empty line
          # But if style is `no_empty_lines`, there must not be an empty line
          body.nil? && style != :no_empty_lines
        end
      end
    end
  end
end
