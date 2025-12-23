# frozen_string_literal: true

module RuboCop
  module Cop
    # This module contains a collection of useful utility methods.
    # rubocop:disable Metrics/ModuleLength
    module Util
      include PathUtil

      # Match literal regex characters, not including anchors, character
      # classes, alternatives, groups, repetitions, references, etc
      LITERAL_REGEX = %r{[\w\s\-,"'!#%&<>=;:`~/]|\\[^AbBdDgGhHkpPRwWXsSzZ0-9]}.freeze

      module_function

      # This is a bad API
      def comment_line?(line_source)
        /^\s*#/.match?(line_source)
      end

      # @deprecated Use `ProcessedSource#line_with_comment?`, `contains_comment?` or similar
      def comment_lines?(node)
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `comment_lines?` is deprecated. Use `ProcessedSource#line_with_comment?`, `contains_comment?` or similar instead.
        WARNING

        processed_source[line_range(node)].any? { |line| comment_line?(line) }
      end

      def line_range(node)
        node.first_line..node.last_line
      end

      def parentheses?(node)
        node.loc_is?(:end, ')')
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def add_parentheses(node, corrector)
        if node.args_type?
          arguments_range = node.source_range
          args_with_space = range_with_surrounding_space(arguments_range, side: :left)
          leading_space = range_between(args_with_space.begin_pos, arguments_range.begin_pos)
          corrector.replace(leading_space, '(')
          corrector.insert_after(arguments_range, ')')
        elsif !node.respond_to?(:arguments)
          corrector.wrap(node, '(', ')')
        elsif node.arguments.empty?
          corrector.insert_after(node, '()')
        else
          args_begin = args_begin(node)

          corrector.remove(args_begin)
          corrector.insert_before(args_begin, '(')
          corrector.insert_after(args_end(node), ')')
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def any_descendant?(node, *types)
        if block_given?
          node.each_descendant(*types) do |descendant|
            return true if yield(descendant)
          end
        else
          # Use a block version to avoid allocating enumerators.
          node.each_descendant do # rubocop:disable Lint/UnreachableLoop
            return true
          end
        end

        false
      end

      def args_begin(node)
        loc = node.loc
        selector = if node.type?(:super, :yield)
                     loc.keyword
                   elsif node.any_def_type?
                     loc.name
                   else
                     loc.selector
                   end
        selector.end.resize(1)
      end

      def args_end(node)
        node.source_range.end
      end

      def on_node(syms, sexp, excludes = [], &block)
        return to_enum(:on_node, syms, sexp, excludes) unless block

        yield sexp if include_or_equal?(syms, sexp.type)
        return if include_or_equal?(excludes, sexp.type)

        sexp.each_child_node { |elem| on_node(syms, elem, excludes, &block) }
      end

      # Arbitrarily chosen value, should be enough to cover
      # the most nested source code in real world projects.
      MAX_LINE_BEGINS_REGEX_INDEX = 50
      LINE_BEGINS_REGEX_CACHE = Hash.new do |hash, index|
        hash[index] = /^\s{#{index}}\S/ if index <= MAX_LINE_BEGINS_REGEX_INDEX
      end
      private_constant :MAX_LINE_BEGINS_REGEX_INDEX, :LINE_BEGINS_REGEX_CACHE

      def begins_its_line?(range)
        if (regex = LINE_BEGINS_REGEX_CACHE[range.column])
          range.source_line.match?(regex)
        else
          range.source_line.index(/\S/) == range.column
        end
      end

      # Returns, for example, a bare `if` node if the given node is an `if`
      # with calls chained to the end of it.
      def first_part_of_call_chain(node)
        while node
          case node.type
          when :send
            node = node.receiver
          when :block
            node = node.send_node
          else
            break
          end
        end
        node
      end

      # If converting a string to Ruby string literal source code, must
      # double quotes be used?
      def double_quotes_required?(string)
        # Double quotes are required for strings which either:
        # - Contain single quotes
        # - Contain non-printable characters, which must use an escape

        # Regex matches IF there is a ' or there is a \\ in the string that is
        # not preceded/followed by another \\ (e.g. "\\x34") but not "\\\\".
        /'|(?<! \\) \\{2}* \\ (?![\\"])/x.match?(string)
      end

      def needs_escaping?(string)
        double_quotes_required?(escape_string(string))
      end

      def escape_string(string)
        string.inspect[1..-2].tap { |s| s.gsub!('\\"', '"') }
      end

      def to_string_literal(string)
        if needs_escaping?(string) && compatible_external_encoding_for?(string)
          string.inspect
        else
          # In a single-quoted strings, double quotes don't need to be escaped
          "'#{string.gsub('\\') { '\\\\' }.gsub('\"', '"')}'"
        end
      end

      def trim_string_interpolation_escape_character(str)
        str.gsub(/\\\#\{(.*?)\}/) { "\#{#{Regexp.last_match(1)}}" }
      end

      def interpret_string_escapes(string)
        StringInterpreter.interpret(string)
      end

      def line(node_or_range)
        if node_or_range.respond_to?(:line)
          node_or_range.line
        elsif node_or_range.respond_to?(:loc)
          node_or_range.loc.line
        end
      end

      def same_line?(node1, node2)
        line1 = line(node1)
        line2 = line(node2)
        return false unless line1 && line2

        line1 == line2
      end

      def indent(node, offset: 0)
        ' ' * (node.loc.column + offset)
      end

      @to_supported_styles_cache = {}

      def to_supported_styles(enforced_style)
        @to_supported_styles_cache[enforced_style] ||=
          enforced_style.sub(/^Enforced/, 'Supported').sub('Style', 'Styles')
      end

      def parse_regexp(text)
        Regexp::Parser.parse(text)
      rescue Regexp::Parser::Error
        # Upon encountering an invalid regular expression,
        # we aim to proceed and identify any remaining potential offenses.
        nil
      end

      private

      def compatible_external_encoding_for?(src)
        src.dup.force_encoding(Encoding.default_external).valid_encoding?
      end

      def include_or_equal?(source, target)
        source == target || (source.is_a?(Array) && source.include?(target))
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
