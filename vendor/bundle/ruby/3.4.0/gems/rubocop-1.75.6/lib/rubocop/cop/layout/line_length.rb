# frozen_string_literal: true

require 'uri'

module RuboCop
  module Cop
    module Layout
      # Checks the length of lines in the source code.
      # The maximum length is configurable.
      # The tab size is configured in the `IndentationWidth`
      # of the `Layout/IndentationStyle` cop.
      # It also ignores a shebang line by default.
      #
      # This cop has some autocorrection capabilities.
      # It can programmatically shorten certain long lines by
      # inserting line breaks into expressions that can be safely
      # split across lines. These include arrays, hashes, and
      # method calls with argument lists.
      #
      # If autocorrection is enabled, the following cops
      # are recommended to further format the broken lines.
      # (Many of these are enabled by default.)
      #
      # * `Layout/ArgumentAlignment`
      # * `Layout/ArrayAlignment`
      # * `Layout/BlockAlignment`
      # * `Layout/BlockEndNewline`
      # * `Layout/ClosingParenthesisIndentation`
      # * `Layout/FirstArgumentIndentation`
      # * `Layout/FirstArrayElementIndentation`
      # * `Layout/FirstHashElementIndentation`
      # * `Layout/FirstParameterIndentation`
      # * `Layout/HashAlignment`
      # * `Layout/IndentationWidth`
      # * `Layout/MultilineArrayLineBreaks`
      # * `Layout/MultilineBlockLayout`
      # * `Layout/MultilineHashBraceLayout`
      # * `Layout/MultilineHashKeyLineBreaks`
      # * `Layout/MultilineMethodArgumentLineBreaks`
      # * `Layout/MultilineMethodParameterLineBreaks`
      # * `Layout/ParameterAlignment`
      # * `Style/BlockDelimiters`
      #
      # Together, these cops will pretty print hashes, arrays,
      # method calls, etc. For example, let's say the max columns
      # is 25:
      #
      # @example
      #
      #   # bad
      #   {foo: "0000000000", bar: "0000000000", baz: "0000000000"}
      #
      #   # good
      #   {foo: "0000000000",
      #   bar: "0000000000", baz: "0000000000"}
      #
      #   # good (with recommended cops enabled)
      #   {
      #     foo: "0000000000",
      #     bar: "0000000000",
      #     baz: "0000000000",
      #   }
      class LineLength < Base # rubocop:disable Metrics/ClassLength
        include CheckLineBreakable
        include AllowedPattern
        include RangeHelp
        include LineLengthHelp
        extend AutoCorrector

        exclude_limit 'Max'

        MSG = 'Line is too long. [%<length>d/%<max>d]'

        def on_block(node)
          check_for_breakable_block(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        def on_str(node)
          check_for_breakable_str(node)
        end

        def on_dstr(node)
          check_for_breakable_dstr(node)
        end

        def on_potential_breakable_node(node)
          check_for_breakable_node(node)
        end
        alias on_array on_potential_breakable_node
        alias on_hash on_potential_breakable_node
        alias on_send on_potential_breakable_node
        alias on_csend on_potential_breakable_node
        alias on_def on_potential_breakable_node
        alias on_defs on_potential_breakable_node

        def on_new_investigation
          return unless processed_source.raw_source.include?(';')

          check_for_breakable_semicolons(processed_source)
        end

        def on_investigation_end
          processed_source.lines.each_with_index do |line, line_index|
            check_line(line, line_index)
          end
        end

        private

        attr_accessor :breakable_range

        def check_for_breakable_node(node)
          breakable_node = extract_breakable_node(node, max)
          return if breakable_node.nil?

          line_index = breakable_node.first_line - 1
          range = breakable_node.source_range

          existing = breakable_range_by_line_index[line_index]
          return if existing

          breakable_range_by_line_index[line_index] = range
        end

        def check_for_breakable_semicolons(processed_source)
          tokens = processed_source.tokens.select { |t| t.type == :tSEMI }
          tokens.reverse_each do |token|
            range = breakable_range_after_semicolon(token)
            breakable_range_by_line_index[range.line - 1] = range if range
          end
        end

        def check_for_breakable_block(block_node)
          return unless block_node.single_line?

          line_index = block_node.loc.line - 1
          range = breakable_block_range(block_node)
          pos = range.begin_pos + 1

          breakable_range_by_line_index[line_index] = range_between(pos, pos + 1)
        end

        def check_for_breakable_str(node)
          line_index = node.loc.line - 1
          return if breakable_range_by_line_index[line_index]

          return unless breakable_string?(node)
          return unless (delimiter = string_delimiter(node))
          return unless (pos = breakable_string_position(node))

          breakable_range_by_line_index[line_index] = range_between(pos, pos + 1)
          breakable_string_delimiters[line_index] = delimiter
        end

        def check_for_breakable_dstr(node) # rubocop:disable Metrics/AbcSize
          line_index = node.loc.line - 1
          return if breakable_range_by_line_index[line_index]

          return unless breakable_dstr?(node)
          return unless (delimiter = string_delimiter(node))

          node.each_child_node(:begin).detect do |begin_node|
            next unless (pos = breakable_dstr_begin_position(begin_node))

            breakable_range_by_line_index[line_index] = range_between(pos, pos + 1)
            breakable_string_delimiters[line_index] = delimiter
          end
        end

        def breakable_string?(node)
          allow_string_split? &&
            node.single_line? &&
            !node.heredoc? &&
            # TODO: strings inside hashes, kwargs and arrays are currently ignored,
            # but could be considered in the future
            !node.parent&.type?(:pair, :kwoptarg, :array)
        end

        def breakable_block_range(block_node)
          if block_node.arguments? && !block_node.lambda?
            block_node.arguments.loc.end
          else
            block_node.braces? ? block_node.loc.begin : block_node.loc.begin.adjust(begin_pos: 1)
          end
        end

        def breakable_range_after_semicolon(semicolon_token)
          range = semicolon_token.pos
          end_pos = range.end_pos
          next_range = range_between(end_pos, end_pos + 1)
          return nil unless same_line?(next_range, range)

          next_char = next_range.source
          return nil if /[\r\n]/.match?(next_char)
          return nil if next_char == ';'

          next_range
        end

        def breakable_string_position(node)
          source_range = node.source_range
          return if source_range.last_column < max
          return unless (pos = breakable_string_range(node))

          pos.end_pos unless pos.end_pos == source_range.begin_pos
        end

        # Locate where to break a string that is too long, ensuring that escape characters
        # are not bisected.
        # If the string contains spaces, use them to determine a place for a clean break;
        # otherwise, the string will be broken at the line length limit.
        def breakable_string_range(node)
          source_range = node.source_range
          relevant_substr = largest_possible_string(node)

          if (space_pos = relevant_substr.rindex(/\s/))
            source_range.resize(space_pos + 1)
          elsif (escape_pos = relevant_substr.rindex(/\\(u[\da-f]{0,4}|x[\da-f]{0,2})?\z/))
            source_range.resize(escape_pos)
          else
            adjustment = max - source_range.last_column - 3
            return if adjustment.abs > source_range.size

            source_range.adjust(end_pos: adjustment)
          end
        end

        def breakable_dstr_begin_position(node)
          source_range = node.source_range
          source_range.begin_pos if source_range.column < max && source_range.last_column >= max
        end

        def breakable_range_by_line_index
          @breakable_range_by_line_index ||= {}
        end

        def breakable_string_delimiters
          @breakable_string_delimiters ||= {}
        end

        def heredocs
          @heredocs ||= extract_heredocs(processed_source.ast)
        end

        def highlight_start(line)
          # TODO: The max with 0 is a quick fix to avoid crashes when a line
          # begins with many tabs, but getting a correct highlighting range
          # when tabs are used for indentation doesn't work currently.
          [max - indentation_difference(line), 0].max
        end

        def check_line(line, line_index)
          return if line_length(line) <= max
          return if allowed_line?(line, line_index)

          if ignore_cop_directives? && directive_on_source_line?(line_index)
            return check_directive_line(line, line_index)
          end
          return check_uri_line(line, line_index) if allow_uri?

          register_offense(excess_range(nil, line, line_index), line, line_index)
        end

        def allowed_line?(line, line_index)
          matches_allowed_pattern?(line) ||
            shebang?(line, line_index) ||
            (heredocs && line_in_permitted_heredoc?(line_index.succ))
        end

        def shebang?(line, line_index)
          line_index.zero? && line.start_with?('#!')
        end

        def register_offense(loc, line, line_index, length: line_length(line))
          message = format(MSG, length: length, max: max)

          self.breakable_range = breakable_range_by_line_index[line_index]

          add_offense(loc, message: message) do |corrector|
            self.max = line_length(line)

            insertion = if (delimiter = breakable_string_delimiters[line_index])
                          [delimiter, " \\\n", delimiter].join
                        else
                          "\n"
                        end

            corrector.insert_before(breakable_range, insertion) unless breakable_range.nil?
          end
        end

        def excess_range(uri_range, line, line_index)
          excessive_position = if uri_range && uri_range.begin < max
                                 uri_range.end
                               else
                                 highlight_start(line)
                               end

          source_range(processed_source.buffer, line_index + 1,
                       excessive_position...(line_length(line)))
        end

        def max
          cop_config['Max']
        end

        def allow_heredoc?
          allowed_heredoc
        end

        def allowed_heredoc
          cop_config['AllowHeredoc']
        end

        def allow_string_split?
          cop_config['SplitStrings']
        end

        def extract_heredocs(ast)
          return [] unless ast

          ast.each_node(:str, :dstr, :xstr).select(&:heredoc?).map do |node|
            body = node.location.heredoc_body
            delimiter = node.location.heredoc_end.source.strip
            [body.first_line...body.last_line, delimiter]
          end
        end

        def line_in_permitted_heredoc?(line_number)
          return false unless allowed_heredoc

          heredocs.any? do |range, delimiter|
            range.cover?(line_number) &&
              (allowed_heredoc == true || allowed_heredoc.include?(delimiter))
          end
        end

        def line_in_heredoc?(line_number)
          heredocs.any? { |range, _delimiter| range.cover?(line_number) }
        end

        def check_directive_line(line, line_index)
          length_without_directive = line_length_without_directive(line)
          return if length_without_directive <= max

          range = max..(length_without_directive - 1)
          register_offense(
            source_range(
              processed_source.buffer,
              line_index + 1,
              range
            ),
            line,
            line_index,
            length: length_without_directive
          )
        end

        def check_uri_line(line, line_index)
          uri_range = find_excessive_uri_range(line)
          return if uri_range && allowed_uri_position?(line, uri_range)

          register_offense(excess_range(uri_range, line, line_index), line, line_index)
        end

        def breakable_dstr?(node)
          # If the `dstr` only contains one child, it cannot be broken
          breakable_string?(node) && !node.child_nodes.one?
        end

        def string_delimiter(node)
          delimiter = node.loc.begin
          if node.parent&.dstr_type? && node.parent.loc.respond_to?(:begin)
            delimiter ||= node.parent.loc.begin
          end
          delimiter = delimiter&.source

          delimiter if %w[' "].include?(delimiter)
        end

        # Find the largest possible substring of a string node to retain before a break
        def largest_possible_string(node)
          # The maximum allowed length of a string value is:
          # `Max` - end delimiter (quote) - continuation characters (space and slash)
          max_length = max - 3
          # If the string doesn't start at the beginning of the line, the max length is offset
          max_length -= column_offset_between(node.loc, node.parent.loc) if node.parent
          node.source[0...(max_length)]
        end
      end
    end
  end
end
