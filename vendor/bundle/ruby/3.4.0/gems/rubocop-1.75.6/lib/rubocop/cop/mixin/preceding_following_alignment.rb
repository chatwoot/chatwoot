# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking whether an AST node/token is aligned
    # with something on a preceding or following line
    # rubocop:disable Metrics/ModuleLength
    module PrecedingFollowingAlignment
      # Tokens that end with an `=`, as well as `<<`, that can be aligned together:
      # `=`, `==`, `===`, `!=`, `<=`, `>=`, `<<` and operator assignment (`+=`, etc).
      ASSIGNMENT_OR_COMPARISON_TOKENS = %i[tEQL tEQ tEQQ tNEQ tLEQ tGEQ tOP_ASGN tLSHFT].freeze

      private

      def allow_for_alignment?
        cop_config['AllowForAlignment']
      end

      def aligned_with_something?(range)
        aligned_with_adjacent_line?(range, method(:aligned_token?))
      end

      def aligned_with_operator?(range)
        aligned_with_adjacent_line?(range, method(:aligned_operator?))
      end

      # Allows alignment with a preceding operator that ends with an `=`,
      # including assignment and comparison operators.
      def aligned_with_preceding_equals_operator(token)
        preceding_line_range = token.line.downto(1)

        aligned_with_equals_sign(token, preceding_line_range)
      end

      # Allows alignment with a subsequent operator that ends with an `=`,
      # including assignment and comparison operators.
      def aligned_with_subsequent_equals_operator(token)
        subsequent_line_range = token.line.upto(processed_source.lines.length)

        aligned_with_equals_sign(token, subsequent_line_range)
      end

      def aligned_with_adjacent_line?(range, predicate)
        # minus 2 because node.loc.line is zero-based
        pre  = (range.line - 2).downto(0)
        post = range.line.upto(processed_source.lines.size - 1)

        aligned_with_any_line_range?([pre, post], range, &predicate)
      end

      def aligned_with_any_line_range?(line_ranges, range, &predicate)
        return true if aligned_with_any_line?(line_ranges, range, &predicate)

        # If no aligned token was found, search for an aligned token on the
        # nearest line with the same indentation as the checked line.
        base_indentation = processed_source.lines[range.line - 1] =~ /\S/

        aligned_with_any_line?(line_ranges, range, base_indentation, &predicate)
      end

      def aligned_with_any_line?(line_ranges, range, indent = nil, &predicate)
        line_ranges.any? { |line_nos| aligned_with_line?(line_nos, range, indent, &predicate) }
      end

      def aligned_with_line?(line_nos, range, indent = nil)
        line_nos.each do |lineno|
          next if aligned_comment_lines.include?(lineno + 1)

          line = processed_source.lines[lineno]
          index = line =~ /\S/
          next unless index
          next if indent && indent != index

          return yield(range, line, lineno + 1)
        end
        false
      end

      def aligned_comment_lines
        @aligned_comment_lines ||=
          processed_source.comments.map(&:loc).select do |r|
            begins_its_line?(r.expression)
          end.map(&:line)
      end

      def aligned_token?(range, line, lineno)
        aligned_words?(range, line) || aligned_equals_operator?(range, lineno)
      end

      def aligned_operator?(range, line, lineno)
        aligned_identical?(range, line) || aligned_equals_operator?(range, lineno)
      end

      def aligned_words?(range, line)
        left_edge = range.column
        return true if /\s\S/.match?(line[left_edge - 1, 2])

        token = range.source
        token == line[left_edge, token.length]
      end

      def aligned_equals_operator?(range, lineno)
        # Check that the operator is aligned with a previous assignment or comparison operator
        # ie. an equals sign, an operator assignment (eg. `+=`), a comparison (`==`, `<=`, etc.).
        # Since append operators (`<<`) are a type of assignment, they are allowed as well,
        # despite not ending with a literal equals character.
        line_range = processed_source.buffer.line_range(lineno)
        return false unless line_range

        # Find the specific token to avoid matching up to operators inside strings
        operator_token = processed_source.tokens_within(line_range).detect do |token|
          ASSIGNMENT_OR_COMPARISON_TOKENS.include?(token.type)
        end

        aligned_with_preceding_equals?(range, operator_token) ||
          aligned_with_append_operator?(range, operator_token)
      end

      def aligned_with_preceding_equals?(range, token)
        return false unless token

        range.source[-1] == '=' && range.last_column == token.pos.last_column
      end

      def aligned_with_append_operator?(range, token)
        return false unless token

        ((range.source == '<<' && token.equal_sign?) ||
          (range.source[-1] == '=' && token.type == :tLSHFT)) &&
          token && range.last_column == token.pos.last_column
      end

      def aligned_identical?(range, line)
        range.source == line[range.column, range.size]
      end

      def aligned_with_equals_sign(token, line_range)
        token_line_indent    = processed_source.line_indentation(token.line)
        assignment_lines     = relevant_assignment_lines(line_range)
        relevant_line_number = assignment_lines[1]

        return :none unless relevant_line_number

        relevant_indent = processed_source.line_indentation(relevant_line_number)

        return :none if relevant_indent < token_line_indent
        return :none unless processed_source.lines[relevant_line_number - 1]

        aligned_equals_operator?(token.pos, relevant_line_number) ? :yes : :no
      end

      def assignment_lines
        @assignment_lines ||= assignment_tokens.map(&:line)
      end

      def assignment_tokens
        @assignment_tokens ||= begin
          tokens = processed_source.tokens.select(&:equal_sign?)

          # We don't want to operate on equals signs which are part of an `optarg` in a
          # method definition, or the separator of an endless method definition.
          # For example (the equals sign to ignore is highlighted with ^):
          #     def method(optarg = default_val); end
          #                       ^
          #     def method = foo
          #                ^
          tokens = remove_equals_in_def(tokens, processed_source)

          # Only attempt to align the first = on each line
          Set.new(tokens.uniq(&:line))
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
      def relevant_assignment_lines(line_range)
        result                        = []
        original_line_indent          = processed_source.line_indentation(line_range.first)
        relevant_line_indent_at_level = true

        line_range.each do |line_number|
          current_line_indent = processed_source.line_indentation(line_number)
          blank_line          = processed_source.lines[line_number - 1].blank?

          if (current_line_indent < original_line_indent && !blank_line) ||
             (relevant_line_indent_at_level && blank_line)
            break
          end

          result << line_number if assignment_lines.include?(line_number) &&
                                   current_line_indent == original_line_indent

          unless blank_line
            relevant_line_indent_at_level = current_line_indent == original_line_indent
          end
        end

        result
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength

      def remove_equals_in_def(asgn_tokens, processed_source)
        nodes = processed_source.ast.each_node(:optarg, :def)
        eqls_to_ignore = nodes.with_object([]) do |node, arr|
          loc = if node.def_type?
                  node.loc.assignment if node.endless?
                else
                  node.loc.operator
                end
          arr << loc.begin_pos if loc
        end

        asgn_tokens.reject { |t| eqls_to_ignore.include?(t.begin_pos) }
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
