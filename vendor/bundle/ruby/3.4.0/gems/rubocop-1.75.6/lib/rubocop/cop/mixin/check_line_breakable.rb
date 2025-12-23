# frozen_string_literal: true

module RuboCop
  module Cop
    # This mixin detects collections that are safe to "break"
    # by inserting new lines. This is useful for breaking
    # up long lines.
    #
    # Let's look at hashes as an example:
    #
    # We know hash keys are safe to break across lines. We can add
    # linebreaks into hashes on lines longer than the specified maximum.
    # Then in further passes cops can clean up the multi-line hash.
    # For example, say the maximum line length is as indicated below:
    #
    #                                         |
    #                                         v
    # {foo: "0000000000", bar: "0000000000", baz: "0000000000"}
    #
    # In a LineLength autocorrection pass, a line is added before
    # the first key that exceeds the column limit:
    #
    # {foo: "0000000000", bar: "0000000000",
    # baz: "0000000000"}
    #
    # In a MultilineHashKeyLineBreaks pass, lines are inserted
    # before all keys:
    #
    # {foo: "0000000000",
    # bar: "0000000000",
    # baz: "0000000000"}
    #
    # Then in future passes FirstHashElementLineBreak,
    # MultilineHashBraceLayout, and TrailingCommaInHashLiteral will
    # manipulate as well until we get:
    #
    # {
    #   foo: "0000000000",
    #   bar: "0000000000",
    #   baz: "0000000000",
    # }
    #
    # (Note: Passes may not happen exactly in this sequence.)
    module CheckLineBreakable
      def extract_breakable_node(node, max)
        if node.call_type?
          return if chained_to_heredoc?(node)

          args = process_args(node.arguments)
          return extract_breakable_node_from_elements(node, args, max)
        elsif node.any_def_type?
          return extract_breakable_node_from_elements(node, node.arguments, max)
        elsif node.type?(:array, :hash)
          return extract_breakable_node_from_elements(node, node.children, max)
        end
        nil
      end

      private

      # @api private
      def extract_breakable_node_from_elements(node, elements, max)
        return unless breakable_collection?(node, elements)
        return if safe_to_ignore?(node)

        line = processed_source.lines[node.first_line - 1]
        return if processed_source.line_with_comment?(node.loc.line)
        return if line.length <= max

        extract_first_element_over_column_limit(node, elements, max)
      end

      # @api private
      def extract_first_element_over_column_limit(node, elements, max)
        line = node.first_line

        # If a `send` or `csend` node is not parenthesized, don't move the first element, because it
        # can result in changed behavior or a syntax error.
        if node.call_type? && !node.parenthesized? && !first_argument_is_heredoc?(node)
          elements = elements.drop(1)
        end

        i = 0
        i += 1 while within_column_limit?(elements[i], max, line)
        i = shift_elements_for_heredoc_arg(node, elements, i)

        return if i.nil?
        return elements.first if i.zero?

        elements[i - 1]
      end

      # @api private
      def first_argument_is_heredoc?(node)
        first_argument = node.first_argument

        first_argument.respond_to?(:heredoc?) && first_argument.heredoc?
      end

      # @api private
      # If a `send` or `csend` node contains a heredoc argument, splitting cannot happen
      # after the heredoc or else it will cause a syntax error.
      def shift_elements_for_heredoc_arg(node, elements, index)
        return index unless node.type?(:call, :array)

        heredoc_index = elements.index { |arg| arg.respond_to?(:heredoc?) && arg.heredoc? }
        return index unless heredoc_index
        return nil if heredoc_index.zero?

        heredoc_index >= index ? index : heredoc_index + 1
      end

      # @api private
      def within_column_limit?(element, max, line)
        element && element.loc.column <= max && element.loc.line == line
      end

      # @api private
      def safe_to_ignore?(node)
        return true unless max
        return true if already_on_multiple_lines?(node)

        # If there's a containing breakable collection on the same
        # line, we let that one get broken first. In a separate pass,
        # this one might get broken as well, but to avoid conflicting
        # or redundant edits, we only mark one offense at a time.
        return true if contained_by_breakable_collection_on_same_line?(node)

        return true if contained_by_multiline_collection_that_could_be_broken_up?(node)

        false
      end

      # @api private
      def breakable_collection?(node, elements)
        # For simplicity we only want to insert breaks in normal
        # hashes wrapped in a set of curly braces like {foo: 1}.
        # That is, not a kwargs hash. For method calls, this ensures
        # the method call is made with parens.
        starts_with_bracket = !node.hash_type? || node.loc.begin

        # If the call has a second argument, we can insert a line
        # break before the second argument and the rest of the
        # argument will get auto-formatted onto separate lines
        # by other cops.
        has_second_element = elements.length >= 2

        starts_with_bracket && has_second_element
      end

      # @api private
      def contained_by_breakable_collection_on_same_line?(node)
        node.each_ancestor.find do |ancestor|
          # Ignore ancestors on different lines.
          break if ancestor.first_line != node.first_line

          if ancestor.type?(:hash, :array)
            elements = ancestor.children
          elsif ancestor.call_type?
            elements = process_args(ancestor.arguments)
          else
            next
          end

          return true if breakable_collection?(ancestor, elements)
        end

        false
      end

      # @api private
      def contained_by_multiline_collection_that_could_be_broken_up?(node)
        node.each_ancestor.find do |ancestor|
          if ancestor.type?(:hash, :array) &&
             breakable_collection?(ancestor, ancestor.children)
            return children_could_be_broken_up?(ancestor.children)
          end

          next unless ancestor.call_type?

          args = process_args(ancestor.arguments)
          return children_could_be_broken_up?(args) if breakable_collection?(ancestor, args)
        end

        false
      end

      # @api private
      def children_could_be_broken_up?(children)
        return false if all_on_same_line?(children)

        last_seen_line = -1
        children.each do |child|
          return true if last_seen_line >= child.first_line

          last_seen_line = child.last_line
        end
        false
      end

      # @api private
      def all_on_same_line?(nodes)
        return true if nodes.empty?

        nodes.first.first_line == nodes.last.last_line
      end

      # @api private
      def process_args(args)
        # If there is a trailing hash arg without explicit braces, like this:
        #
        #    method(1, 'key1' => value1, 'key2' => value2)
        #
        # ...then each key/value pair is treated as a method 'argument'
        # when determining where line breaks should appear.
        last_arg = args.last
        args = args[0...-1] + last_arg.children if last_arg&.hash_type? && !last_arg&.braces?
        args
      end

      # @api private
      def already_on_multiple_lines?(node)
        return node.first_line != node.last_argument.last_line if node.any_def_type?

        !node.single_line?
      end

      def chained_to_heredoc?(node)
        while (node = node.receiver)
          return true if node.type?(:str, :dstr, :xstr) && node.heredoc?
        end

        false
      end
    end
  end
end
