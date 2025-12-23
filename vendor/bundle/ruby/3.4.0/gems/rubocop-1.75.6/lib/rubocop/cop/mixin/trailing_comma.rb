# frozen_string_literal: true

module RuboCop
  module Cop
    # Common methods shared by Style/TrailingCommaInArguments,
    # Style/TrailingCommaInArrayLiteral and Style/TrailingCommaInHashLiteral
    # rubocop:disable Metrics/ModuleLength
    module TrailingComma
      include ConfigurableEnforcedStyle
      include RangeHelp

      MSG = '%<command>s comma after the last %<unit>s.'

      private

      def style_parameter_name
        'EnforcedStyleForMultiline'
      end

      def check(node, items, kind, begin_pos, end_pos)
        after_last_item = range_between(begin_pos, end_pos)
        comma_offset = comma_offset(items, after_last_item)

        if comma_offset && !inside_comment?(after_last_item, comma_offset)
          check_comma(node, kind, after_last_item.begin_pos + comma_offset)
        elsif should_have_comma?(style, node)
          put_comma(items, kind)
        end
      end

      def comma_offset(items, range)
        # If there is any heredoc in items, then match the comma succeeding
        # any whitespace (except newlines), otherwise allow for newlines
        comma_regex = any_heredoc?(items) ? /\A[^\S\n]*,/ : /\A\s*,/
        comma_regex.match?(range.source) && range.source.index(',')
      end

      def check_comma(node, kind, comma_pos)
        return if should_have_comma?(style, node)

        avoid_comma(kind, comma_pos, extra_avoid_comma_info)
      end

      def check_literal(node, kind)
        return if node.children.empty?
        # A braceless hash is the last parameter of a method call and will be
        # checked as such.
        return unless brackets?(node)

        check(node, node.children, kind,
              node.children.last.source_range.end_pos,
              node.loc.end.begin_pos)
      end

      def extra_avoid_comma_info
        case style
        when :comma
          ', unless each item is on its own line'
        when :consistent_comma
          ', unless items are split onto multiple lines'
        when :diff_comma
          ', unless that item immediately precedes a newline'
        else
          ''
        end
      end

      def should_have_comma?(style, node)
        case style
        when :comma
          multiline?(node) && no_elements_on_same_line?(node)
        when :consistent_comma
          multiline?(node) && !method_name_and_arguments_on_same_line?(node)
        when :diff_comma
          multiline?(node) && last_item_precedes_newline?(node)
        else
          false
        end
      end

      def inside_comment?(range, comma_offset)
        comment = processed_source.comment_at_line(range.line)
        comment && comment.source_range.begin_pos < range.begin_pos + comma_offset
      end

      # Returns true if the node has round/square/curly brackets.
      def brackets?(node)
        node.loc.end
      end

      # Returns true if the round/square/curly brackets of the given node are
      # on different lines, each item within is on its own line, and the
      # closing bracket is on its own line.
      def multiline?(node)
        node.multiline? && !allowed_multiline_argument?(node)
      end

      def method_name_and_arguments_on_same_line?(node)
        return false unless node.call_type?

        line = node.loc.selector.nil? ? node.loc.line : node.loc.selector.line

        line == node.last_argument.last_line && node.last_line == node.last_argument.last_line
      end

      # A single argument with the closing bracket on the same line as the end
      # of the argument is not considered multiline, even if the argument
      # itself might span multiple lines.
      def allowed_multiline_argument?(node)
        elements(node).one? && !Util.begins_its_line?(node_end_location(node))
      end

      def elements(node)
        return node.children unless node.call_type?

        node.arguments.flat_map do |argument|
          # For each argument, if it is a multi-line hash without braces,
          # then promote the hash elements to method arguments
          # for the purpose of determining multi-line-ness.
          if argument.hash_type? && argument.multiline? && !argument.braces?
            argument.children
          else
            argument
          end
        end
      end

      def no_elements_on_same_line?(node)
        items = elements(node).map(&:source_range)
        items << node_end_location(node)
        items.each_cons(2).none? { |a, b| on_same_line?(a, b) }
      end

      def node_end_location(node)
        node.loc.end || node.source_range.end.adjust(begin_pos: -1)
      end

      def on_same_line?(range1, range2)
        range1.last_line == range2.line
      end

      def last_item_precedes_newline?(node)
        after_last_item = node.children.last.source_range.end.join(node.loc.end.begin)

        after_last_item.source.start_with?(/,?\s*(#.*)?\n/)
      end

      def avoid_comma(kind, comma_begin_pos, extra_info)
        range = range_between(comma_begin_pos, comma_begin_pos + 1)
        article = kind.include?('array') ? 'an' : 'a'
        msg = format(
          MSG,
          command: 'Avoid',
          unit: format(kind, article: article) + extra_info.to_s
        )

        add_offense(range, message: msg) do |corrector|
          PunctuationCorrector.swap_comma(corrector, range)
        end
      end

      def put_comma(items, kind)
        last_item = items.last
        return if last_item.block_pass_type?

        range = autocorrect_range(last_item)
        msg = format(MSG, command: 'Put a', unit: format(kind, article: 'a multiline'))

        add_offense(range, message: msg) do |corrector|
          PunctuationCorrector.swap_comma(corrector, range)
        end
      end

      def autocorrect_range(item)
        expr = item.source_range
        ix = expr.source.rindex("\n") || 0
        ix += expr.source[ix..] =~ /\S/

        range_between(expr.begin_pos + ix, expr.end_pos)
      end

      def any_heredoc?(items)
        items.any? { |item| heredoc?(item) }
      end

      def heredoc?(node)
        return false unless node.is_a?(RuboCop::AST::Node)
        return true if node.loc.respond_to?(:heredoc_body)

        return heredoc_send?(node) if node.send_type?

        # handle hash values
        #
        #   some_method({
        #     'auth' => <<-SOURCE
        #       ...
        #     SOURCE
        #   })
        return heredoc?(node.children.last) if node.type?(:pair, :hash)

        false
      end

      def heredoc_send?(node)
        # handle heredocs with methods
        #
        #   some_method(<<-CODE.strip.chomp)
        #     ...
        #   CODE
        return heredoc?(node.children.first) if node.children.size == 2
        # handle nested methods
        #
        #   some_method(
        #     another_method(<<-CODE.strip.chomp)
        #       ...
        #     CODE
        #   )
        return heredoc?(node.children.last) if node.children.size > 2

        false
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
