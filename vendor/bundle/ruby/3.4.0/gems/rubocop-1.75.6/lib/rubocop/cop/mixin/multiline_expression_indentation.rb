# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking multiline method calls and binary
    # operations.
    module MultilineExpressionIndentation # rubocop:disable Metrics/ModuleLength
      KEYWORD_ANCESTOR_TYPES  = %i[for if while until return].freeze
      UNALIGNED_RHS_TYPES     = %i[if while until for return array kwbegin].freeze
      DEFAULT_MESSAGE_TAIL    = 'an expression'
      ASSIGNMENT_MESSAGE_TAIL = 'an expression in an assignment'
      KEYWORD_MESSAGE_TAIL    = 'a %<kind>s in %<article>s `%<keyword>s` statement'

      def on_send(node)
        return if !node.receiver || node.method?(:[])
        return unless relevant_node?(node)

        lhs = left_hand_side(node.receiver)
        rhs = right_hand_side(node)
        return unless rhs

        range = offending_range(node, lhs, rhs, style)
        check(range, node, lhs, rhs)
      end
      alias on_csend on_send

      private

      # In a chain of method calls, we regard the top call node as the base
      # for indentation of all lines following the first. For example:
      # a.
      #   b c { block }.            <-- b is indented relative to a
      #   d                         <-- d is indented relative to a
      def left_hand_side(lhs)
        while lhs.parent&.call_type? && lhs.parent.loc.dot && !lhs.parent.assignment_method?
          lhs = lhs.parent
        end
        lhs
      end

      # The correct indentation of `node` is usually `IndentationWidth`, with
      # one exception: prefix keywords.
      #
      # ```
      # while foo &&  # Here, `while` is called a "prefix keyword"
      #     bar       # This is called "special indentation"
      #   baz
      # end
      # ```
      #
      # Note that *postfix conditionals* do *not* get "special indentation".
      #
      # ```
      # next if foo &&
      #   bar # normal indentation, not special
      # ```
      def correct_indentation(node)
        kw_node = kw_node_with_special_indentation(node)
        if kw_node && !postfix_conditional?(kw_node)
          # This cop could have its own IndentationWidth configuration
          configured_indentation_width + @config.for_cop('Layout/IndentationWidth')['Width']
        else
          configured_indentation_width
        end
      end

      def check(range, node, lhs, rhs)
        if range
          incorrect_style_detected(range, node, lhs, rhs)
        else
          correct_style_detected
        end
      end

      def incorrect_style_detected(range, node, lhs, rhs)
        add_offense(range, message: message(node, lhs, rhs)) do |corrector|
          autocorrect(corrector, range)

          if supported_styles.size > 2 || offending_range(node, lhs, rhs, alternative_style)
            unrecognized_style_detected
          else
            opposite_style_detected
          end
        end
      end

      def indentation(node)
        node.source_range.source_line =~ /\S/
      end

      def operation_description(node, rhs)
        kw_node_with_special_indentation(node) do |ancestor|
          return keyword_message_tail(ancestor)
        end

        part_of_assignment_rhs(node, rhs) { |_node| return ASSIGNMENT_MESSAGE_TAIL }

        DEFAULT_MESSAGE_TAIL
      end

      def keyword_message_tail(node)
        keyword = node.loc.keyword.source
        kind    = keyword == 'for' ? 'collection' : 'condition'
        article = keyword.start_with?('i', 'u') ? 'an' : 'a'

        format(KEYWORD_MESSAGE_TAIL, kind: kind, article: article, keyword: keyword)
      end

      def kw_node_with_special_indentation(node)
        keyword_node =
          node.each_ancestor(*KEYWORD_ANCESTOR_TYPES).find do |ancestor|
            next if ancestor.if_type? && ancestor.ternary?

            within_node?(node, indented_keyword_expression(ancestor))
          end

        if keyword_node && block_given?
          yield keyword_node
        else
          keyword_node
        end
      end

      def indented_keyword_expression(node)
        if node.for_type?
          node.collection
        else
          node.children.first
        end
      end

      def argument_in_method_call(node, kind) # rubocop:todo Metrics/CyclomaticComplexity
        node.each_ancestor(:send, :block).find do |a|
          # If the node is inside a block, it makes no difference if that block
          # is an argument in a method call. It doesn't count.
          break false if a.block_type?

          next if a.setter_method?
          next unless kind == :with_or_without_parentheses ||
                      (kind == :with_parentheses && parentheses?(a))

          a.arguments.any? { |arg| within_node?(node, arg) }
        end
      end

      def part_of_assignment_rhs(node, candidate)
        rhs_node = node.each_ancestor.find do |ancestor|
          break if disqualified_rhs?(candidate, ancestor)

          valid_rhs?(candidate, ancestor)
        end

        if rhs_node && block_given?
          yield rhs_node
        else
          rhs_node
        end
      end

      def disqualified_rhs?(candidate, ancestor)
        UNALIGNED_RHS_TYPES.include?(ancestor.type) ||
          (ancestor.block_type? && part_of_block_body?(candidate, ancestor))
      end

      def valid_rhs?(candidate, ancestor)
        if ancestor.send_type?
          valid_method_rhs_candidate?(candidate, ancestor)
        elsif ancestor.assignment?
          valid_rhs_candidate?(candidate, assignment_rhs(ancestor))
        else
          false
        end
      end

      # The []= operator and setters (a.b = c) are parsed as :send nodes.
      def valid_method_rhs_candidate?(candidate, node)
        node.setter_method? && valid_rhs_candidate?(candidate, node.last_argument)
      end

      def valid_rhs_candidate?(candidate, node)
        !candidate || within_node?(candidate, node)
      end

      def part_of_block_body?(candidate, block_node)
        block_node.body && within_node?(candidate, block_node.body)
      end

      def assignment_rhs(node)
        case node.type
        when :casgn, :op_asgn then node.rhs
        when :send, :csend    then node.last_argument
        else                       node.children.last
        end
      end

      def not_for_this_cop?(node)
        node.ancestors.any? do |ancestor|
          grouped_expression?(ancestor) || inside_arg_list_parentheses?(node, ancestor)
        end
      end

      def grouped_expression?(node)
        node.begin_type? && node.loc.respond_to?(:begin) && node.loc.begin
      end

      def inside_arg_list_parentheses?(node, ancestor)
        return false unless ancestor.send_type? && ancestor.parenthesized?

        node.source_range.begin_pos > ancestor.loc.begin.begin_pos &&
          node.source_range.end_pos < ancestor.loc.end.end_pos
      end

      # Returns true if `node` is a conditional whose `body` and `condition`
      # begin on the same line.
      def postfix_conditional?(node)
        node.if_type? && node.modifier_form?
      end

      def within_node?(inner, outer)
        o = outer.is_a?(AST::Node) ? outer.source_range : outer
        i = inner.is_a?(AST::Node) ? inner.source_range : inner
        i.begin_pos >= o.begin_pos && i.end_pos <= o.end_pos
      end
    end
  end
end
