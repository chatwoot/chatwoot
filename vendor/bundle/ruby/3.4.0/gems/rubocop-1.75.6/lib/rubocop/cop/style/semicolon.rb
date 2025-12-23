# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for multiple expressions placed on the same line.
      # It also checks for lines terminated with a semicolon.
      #
      # This cop has `AllowAsExpressionSeparator` configuration option.
      # It allows `;` to separate several expressions on the same line.
      #
      # @example
      #   # bad
      #   foo = 1; bar = 2;
      #   baz = 3;
      #
      #   # good
      #   foo = 1
      #   bar = 2
      #   baz = 3
      #
      # @example AllowAsExpressionSeparator: false (default)
      #   # bad
      #   foo = 1; bar = 2
      #
      # @example AllowAsExpressionSeparator: true
      #   # good
      #   foo = 1; bar = 2
      class Semicolon < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use semicolons to terminate expressions.'

        def self.autocorrect_incompatible_with
          [Style::SingleLineMethods]
        end

        def on_new_investigation
          return if processed_source.blank? || !processed_source.raw_source.include?(';')

          check_for_line_terminator_or_opener
        end

        def on_begin(node)
          return if cop_config['AllowAsExpressionSeparator']
          return unless node.source.include?(';')

          exprs = node.children

          return if exprs.size < 2

          expressions_per_line(exprs).each do |line, expr_on_line|
            # Every line with more than one expression on it is a
            # potential offense
            next unless expr_on_line.size > 1

            find_semicolon_positions(line) { |pos| register_semicolon(line, pos, true) }
          end
        end

        private

        def check_for_line_terminator_or_opener
          each_semicolon do |line, column, token_before_semicolon|
            register_semicolon(line, column, false, token_before_semicolon)
          end
        end

        def each_semicolon
          tokens_for_lines.each do |line, tokens|
            semicolon_pos = semicolon_position(tokens)
            after_expr_pos = semicolon_pos == -1 ? -2 : semicolon_pos

            yield line, tokens[semicolon_pos].column, tokens[after_expr_pos] if semicolon_pos
          end
        end

        def tokens_for_lines
          processed_source.tokens.group_by(&:line)
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def semicolon_position(tokens)
          if tokens.last.semicolon?
            -1
          elsif tokens.first.semicolon?
            0
          elsif exist_semicolon_before_right_curly_brace?(tokens)
            -3
          elsif exist_semicolon_after_left_curly_brace?(tokens) ||
                exist_semicolon_after_left_string_interpolation_brace?(tokens)
            2
          elsif exist_semicolon_after_left_lambda_curly_brace?(tokens)
            3
          elsif exist_semicolon_before_right_string_interpolation_brace?(tokens)
            -4
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def exist_semicolon_before_right_curly_brace?(tokens)
          tokens[-2]&.right_curly_brace? && tokens[-3]&.semicolon?
        end

        def exist_semicolon_after_left_curly_brace?(tokens)
          tokens[1]&.left_curly_brace? && tokens[2]&.semicolon?
        end

        def exist_semicolon_after_left_lambda_curly_brace?(tokens)
          tokens[2]&.type == :tLAMBEG && tokens[3]&.semicolon?
        end

        def exist_semicolon_before_right_string_interpolation_brace?(tokens)
          tokens[-3]&.type == :tSTRING_DEND && tokens[-4]&.semicolon?
        end

        def exist_semicolon_after_left_string_interpolation_brace?(tokens)
          tokens[1]&.type == :tSTRING_DBEG && tokens[2]&.semicolon?
        end

        def register_semicolon(line, column, after_expression, token_before_semicolon = nil)
          range = source_range(processed_source.buffer, line, column)

          add_offense(range) do |corrector|
            if after_expression
              corrector.replace(range, "\n")
            else
              # Prevents becoming one range instance with subsequent line when endless range
              # without parentheses.
              # See: https://github.com/rubocop/rubocop/issues/10791
              if token_before_semicolon&.regexp_dots?
                range_node = find_range_node(token_before_semicolon)
                corrector.wrap(range_node, '(', ')') if range_node
              end

              corrector.remove(range)
            end
          end
        end

        def expressions_per_line(exprs)
          # create a map matching lines to the number of expressions on them
          exprs_lines = exprs.map(&:last_line)
          exprs_lines.group_by(&:itself)
        end

        def find_semicolon_positions(line)
          # Scan for all the semicolons on the line
          semicolons = processed_source[line - 1].enum_for(:scan, ';')
          semicolons.each do
            yield Regexp.last_match.begin(0)
          end
        end

        def find_range_node(token_before_semicolon)
          range_nodes.detect do |range_node|
            range_node.source_range.contains?(token_before_semicolon.pos)
          end
        end

        def range_nodes
          return @range_nodes if instance_variable_defined?(:@range_nodes)

          ast = processed_source.ast
          @range_nodes = ast.range_type? ? [ast] : []
          @range_nodes.concat(ast.each_descendant(:range).to_a)
        end
      end
    end
  end
end
