# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Transforms usages of a method call safeguarded by a non `nil`
      # check for the variable whose method is being called to
      # safe navigation (`&.`). If there is a method chain, all of the methods
      # in the chain need to be checked for safety, and all of the methods will
      # need to be changed to use safe navigation.
      #
      # The default for `ConvertCodeThatCanStartToReturnNil` is `false`.
      # When configured to `true`, this will
      # check for code in the format `!foo.nil? && foo.bar`. As it is written,
      # the return of this code is limited to `false` and whatever the return
      # of the method is. If this is converted to safe navigation,
      # `foo&.bar` can start returning `nil` as well as what the method
      # returns.
      #
      # The default for `MaxChainLength` is `2`.
      # We have limited the cop to not register an offense for method chains
      # that exceed this option's value.
      #
      # NOTE: This cop will recognize offenses but not autocorrect code when the
      # right hand side (RHS) of the `&&` statement is an `||` statement
      # (eg. `foo && (foo.bar? || foo.baz?)`). It can be corrected
      # manually by removing the `foo &&` and adding `&.` to each `foo` on the RHS.
      #
      # @safety
      #   Autocorrection is unsafe because if a value is `false`, the resulting
      #   code will have different behavior or raise an error.
      #
      #   [source,ruby]
      #   ----
      #   x = false
      #   x && x.foo  # return false
      #   x&.foo      # raises NoMethodError
      #   ----
      #
      # @example
      #   # bad
      #   foo.bar if foo
      #   foo.bar.baz if foo
      #   foo.bar(param1, param2) if foo
      #   foo.bar { |e| e.something } if foo
      #   foo.bar(param) { |e| e.something } if foo
      #
      #   foo.bar if !foo.nil?
      #   foo.bar unless !foo
      #   foo.bar unless foo.nil?
      #
      #   foo && foo.bar
      #   foo && foo.bar.baz
      #   foo && foo.bar(param1, param2)
      #   foo && foo.bar { |e| e.something }
      #   foo && foo.bar(param) { |e| e.something }
      #
      #   foo ? foo.bar : nil
      #   foo.nil? ? nil : foo.bar
      #   !foo.nil? ? foo.bar : nil
      #   !foo ? nil : foo.bar
      #
      #   # good
      #   foo&.bar
      #   foo&.bar&.baz
      #   foo&.bar(param1, param2)
      #   foo&.bar { |e| e.something }
      #   foo&.bar(param) { |e| e.something }
      #   foo && foo.bar.baz.qux # method chain with more than 2 methods
      #   foo && foo.nil? # method that `nil` responds to
      #
      #   # Method calls that do not use `.`
      #   foo && foo < bar
      #   foo < bar if foo
      #
      #   # When checking `foo&.empty?` in a conditional, `foo` being `nil` will actually
      #   # do the opposite of what the author intends.
      #   foo && foo.empty?
      #
      #   # This could start returning `nil` as well as the return of the method
      #   foo.nil? || foo.bar
      #   !foo || foo.bar
      #
      #   # Methods that are used on assignment, arithmetic operation or
      #   # comparison should not be converted to use safe navigation
      #   foo.baz = bar if foo
      #   foo.baz + bar if foo
      #   foo.bar > 2 if foo
      class SafeNavigation < Base # rubocop:disable Metrics/ClassLength
        include NilMethods
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use safe navigation (`&.`) instead of checking if an object ' \
              'exists before calling the method.'
        LOGIC_JUMP_KEYWORDS = %i[break fail next raise return throw yield].freeze

        minimum_target_ruby_version 2.3

        # if format: (if checked_variable body nil)
        # unless format: (if checked_variable nil body)
        # @!method modifier_if_safe_navigation_candidate(node)
        def_node_matcher :modifier_if_safe_navigation_candidate, <<~PATTERN
          {
            (if {
                  (send $_ {:nil? :!})
                  $_
                } nil? $_)

            (if {
                  (send (send $_ :nil?) :!)
                  $_
                } $_ nil?)
          }
        PATTERN

        # @!method ternary_safe_navigation_candidate(node)
        def_node_matcher :ternary_safe_navigation_candidate, <<~PATTERN
          {
            (if (send $_ {:nil? :!}) nil $_)

            (if (send (send $_ :nil?) :!) $_ nil)

            (if $_ $_ nil)
          }
        PATTERN

        # @!method and_with_rhs_or?(node)
        def_node_matcher :and_with_rhs_or?, '(and _ {or (begin or)})'

        # @!method not_nil_check?(node)
        def_node_matcher :not_nil_check?, '(send (send $_ :nil?) :!)'

        # @!method and_inside_begin?(node)
        def_node_matcher :and_inside_begin?, '`(begin and ...)'

        # @!method strip_begin(node)
        def_node_matcher :strip_begin, '{ (begin $!begin) $!(begin) }'

        def on_if(node)
          return if allowed_if_condition?(node)

          checked_variable, receiver, method_chain, _method = extract_parts_from_if(node)
          return unless offending_node?(node, checked_variable, method_chain, receiver)

          body = extract_if_body(node)
          method_call = receiver.parent

          removal_ranges = [begin_range(node, body), end_range(node, body)]

          report_offense(node, method_chain, method_call, *removal_ranges) do |corrector|
            corrector.insert_before(method_call.loc.dot, '&') unless method_call.safe_navigation?
          end
        end

        def on_and(node) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
          collect_and_clauses(node).each do |(lhs, lhs_operator_range), (rhs, _rhs_operator_range)|
            lhs_not_nil_check = not_nil_check?(lhs)
            lhs_receiver = lhs_not_nil_check || lhs
            rhs_receiver = find_matching_receiver_invocation(strip_begin(rhs), lhs_receiver)

            next if !cop_config['ConvertCodeThatCanStartToReturnNil'] && lhs_not_nil_check
            next unless offending_node?(node, lhs_receiver, rhs, rhs_receiver)

            # Since we are evaluating every clause in potentially a complex chain of `and` nodes,
            # we need to ensure that there isn't an object check happening
            lhs_method_chain = find_method_chain(lhs_receiver)
            next unless lhs_method_chain == lhs_receiver || lhs_not_nil_check

            report_offense(
              node,
              rhs, rhs_receiver,
              range_with_surrounding_space(range: lhs.source_range, side: :right),
              range_with_surrounding_space(range: lhs_operator_range, side: :right),
              offense_range: range_between(lhs.source_range.begin_pos, rhs.source_range.end_pos)
            ) do |corrector|
              corrector.replace(rhs_receiver, lhs_receiver.source)
            end
            ignore_node(node)
          end
        end

        def report_offense(node, rhs, rhs_receiver, *removal_ranges, offense_range: node)
          add_offense(offense_range) do |corrector|
            next if ignored_node?(node)

            # If the RHS is an `or` we cannot safely autocorrect because in order to remove
            # the non-nil check we need to add safe-navs to all clauses where the receiver is used
            next if and_with_rhs_or?(node)

            removal_ranges.each { |range| corrector.remove(range) }
            yield corrector if block_given?

            handle_comments(corrector, node, rhs)

            add_safe_nav_to_all_methods_in_chain(corrector, rhs_receiver, rhs)
          end
        end

        private

        def find_method_chain(node)
          return node unless node&.parent&.call_type?

          find_method_chain(node.parent)
        end

        def collect_and_clauses(node)
          # Collect the lhs, operator and rhs of all `and` nodes
          # `and` nodes can be nested and can contain `begin` nodes
          # This gives us a source-ordered list of clauses that is then used to look
          # for matching receivers as well as operator locations for offense and corrections
          node.each_descendant(:and)
              .inject(and_parts(node)) { |nodes, and_node| concat_nodes(nodes, and_node) }
              .sort_by { |a| a.is_a?(RuboCop::AST::Node) ? a.source_range.begin_pos : a.begin_pos }
              .each_slice(2)
              .each_cons(2)
        end

        def concat_nodes(nodes, and_node)
          return nodes if and_node.each_ancestor(:block).any?

          nodes.concat(and_parts(and_node))
        end

        def and_parts(node)
          parts = [node.loc.operator]
          parts << node.rhs unless and_inside_begin?(node.rhs)
          parts << node.lhs unless node.lhs.and_type? || and_inside_begin?(node.lhs)
          parts
        end

        def offending_node?(node, lhs_receiver, rhs, rhs_receiver) # rubocop:disable Metrics/CyclomaticComplexity
          return false if !matching_nodes?(lhs_receiver, rhs_receiver) || rhs_receiver.nil?
          return false if use_var_only_in_unless_modifier?(node, lhs_receiver)
          return false if chain_length(rhs, rhs_receiver) > max_chain_length
          return false if unsafe_method_used?(rhs, rhs_receiver.parent)
          return false if rhs.send_type? && rhs.method?(:empty?)

          true
        end

        def use_var_only_in_unless_modifier?(node, variable)
          node.if_type? && node.unless? && !method_called?(variable)
        end

        def extract_if_body(node)
          if node.ternary?
            node.branches.find { |branch| !branch.nil_type? }
          else
            node.node_parts[1]
          end
        end

        def handle_comments(corrector, node, method_call)
          comments = comments(node)
          return if comments.empty?

          corrector.insert_before(method_call, "#{comments.map(&:text).join("\n")}\n")
        end

        def comments(node)
          relevant_comment_ranges(node).each.with_object([]) do |range, comments|
            comments.concat(processed_source.each_comment_in_lines(range).to_a)
          end
        end

        def relevant_comment_ranges(node)
          # Get source lines ranges inside the if node that aren't inside an inner node
          # Comments inside an inner node should remain attached to that node, and not
          # moved.
          begin_pos = node.loc.first_line
          end_pos = node.loc.last_line

          node.child_nodes.each.with_object([]) do |child, ranges|
            ranges << (begin_pos...child.loc.first_line)
            begin_pos = child.loc.last_line
          end << (begin_pos...end_pos)
        end

        def allowed_if_condition?(node)
          node.else? || node.elsif?
        end

        def extract_parts_from_if(node)
          variable, receiver =
            if node.ternary?
              ternary_safe_navigation_candidate(node)
            else
              modifier_if_safe_navigation_candidate(node)
            end

          checked_variable, matching_receiver, method = extract_common_parts(receiver, variable)

          matching_receiver = nil if receiver && LOGIC_JUMP_KEYWORDS.include?(receiver.type)

          [checked_variable, matching_receiver, receiver, method]
        end

        def extract_common_parts(method_chain, checked_variable)
          matching_receiver = find_matching_receiver_invocation(method_chain, checked_variable)

          method = matching_receiver.parent if matching_receiver

          [checked_variable, matching_receiver, method]
        end

        def find_matching_receiver_invocation(method_chain, checked_variable)
          return nil unless method_chain.respond_to?(:receiver)

          receiver = method_chain.receiver

          return receiver if matching_nodes?(receiver, checked_variable)

          find_matching_receiver_invocation(receiver, checked_variable)
        end

        def matching_nodes?(left, right)
          left == right || matching_call_nodes?(left, right)
        end

        def matching_call_nodes?(left, right)
          return false unless left && right.respond_to?(:call_type?)

          left.call_type? && right.call_type? && left.children == right.children
        end

        def chain_length(method_chain, method)
          method.each_ancestor(:call).inject(0) do |total, ancestor|
            break total + 1 if ancestor == method_chain

            total + 1
          end
        end

        def unsafe_method_used?(method_chain, method)
          return true if unsafe_method?(method)

          method.each_ancestor(:send).any? do |ancestor|
            break true unless config.cop_enabled?('Lint/SafeNavigationChain')

            break true if unsafe_method?(ancestor)
            break true if nil_methods.include?(ancestor.method_name)
            break false if ancestor == method_chain
          end
        end

        def unsafe_method?(send_node)
          negated?(send_node) ||
            send_node.assignment? ||
            (!send_node.dot? && !send_node.safe_navigation?)
        end

        def negated?(send_node)
          if method_called?(send_node)
            negated?(send_node.parent)
          else
            send_node.send_type? && send_node.method?(:!)
          end
        end

        def method_called?(send_node)
          send_node&.parent&.send_type?
        end

        def begin_range(node, method_call)
          range_between(node.source_range.begin_pos, method_call.source_range.begin_pos)
        end

        def end_range(node, method_call)
          range_between(method_call.source_range.end_pos, node.source_range.end_pos)
        end

        def add_safe_nav_to_all_methods_in_chain(corrector,
                                                 start_method,
                                                 method_chain)
          start_method.each_ancestor do |ancestor|
            break unless %i[send block].include?(ancestor.type)
            next unless ancestor.send_type?
            next if ancestor.safe_navigation?

            corrector.insert_before(ancestor.loc.dot, '&')

            break if ancestor == method_chain
          end
        end

        def max_chain_length
          cop_config.fetch('MaxChainLength', 2)
        end
      end
    end
  end
end
