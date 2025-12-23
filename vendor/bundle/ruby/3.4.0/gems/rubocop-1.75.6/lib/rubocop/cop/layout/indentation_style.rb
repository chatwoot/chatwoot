# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that the indentation method is consistent.
      # Either tabs only or spaces only are used for indentation.
      #
      # @example EnforcedStyle: spaces (default)
      #   # bad
      #   # This example uses a tab to indent bar.
      #   def foo
      #     bar
      #   end
      #
      #   # good
      #   # This example uses spaces to indent bar.
      #   def foo
      #     bar
      #   end
      #
      # @example EnforcedStyle: tabs
      #   # bad
      #   # This example uses spaces to indent bar.
      #   def foo
      #     bar
      #   end
      #
      #   # good
      #   # This example uses a tab to indent bar.
      #   def foo
      #     bar
      #   end
      class IndentationStyle < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = '%<type>s detected in indentation.'

        def on_new_investigation
          str_ranges = nil

          processed_source.lines.each.with_index(1) do |line, lineno|
            next unless (range = find_offense(line, lineno))

            # Perform costly calculation only when needed.
            str_ranges ||= string_literal_ranges(processed_source.ast)
            next if in_string_literal?(str_ranges, range)

            add_offense(range) { |corrector| autocorrect(corrector, range) }
          end
        end

        private

        def autocorrect(corrector, range)
          if range.source.include?("\t")
            autocorrect_lambda_for_tabs(corrector, range)
          else
            autocorrect_lambda_for_spaces(corrector, range)
          end
        end

        def find_offense(line, lineno)
          match = if style == :spaces
                    line.match(/\A\s*\t+/)
                  else
                    line.match(/\A\s* +/)
                  end
          return unless match

          source_range(processed_source.buffer, lineno, match.begin(0)...match.end(0))
        end

        def autocorrect_lambda_for_tabs(corrector, range)
          spaces = ' ' * configured_indentation_width
          corrector.replace(range, range.source.gsub("\t", spaces))
        end

        def autocorrect_lambda_for_spaces(corrector, range)
          corrector.replace(range, range.source.gsub(/\A\s+/) do |match|
            "\t" * (match.size / configured_indentation_width)
          end)
        end

        def in_string_literal?(ranges, tabs_range)
          ranges.any? { |range| range.contains?(tabs_range) }
        end

        def string_literal_ranges(ast)
          # which lines start inside a string literal?
          return [] if ast.nil?

          ranges = Set.new
          ast.each_node(:str, :dstr) do |str|
            loc = str.location

            if str.heredoc?
              ranges << loc.heredoc_body
            elsif loc.respond_to?(:begin) && loc.begin
              ranges << loc.expression
            end
          end
          ranges
        end

        def message(_node)
          format(MSG, type: style == :spaces ? 'Tab' : 'Space')
        end
      end
    end
  end
end
