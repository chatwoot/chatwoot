# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.4, `String#match?`, `Regexp#match?`, and `Symbol#match?`
      # have been added. The methods are faster than `match`.
      # Because the methods avoid creating a `MatchData` object or saving
      # backref.
      # So, when `MatchData` is not used, use `match?` instead of `match`.
      #
      # @example
      #   # bad
      #   def foo
      #     if x =~ /re/
      #       do_something
      #     end
      #   end
      #
      #   # bad
      #   def foo
      #     if x !~ /re/
      #       do_something
      #     end
      #   end
      #
      #   # bad
      #   def foo
      #     if x.match(/re/)
      #       do_something
      #     end
      #   end
      #
      #   # bad
      #   def foo
      #     if /re/ === x
      #       do_something
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     if x.match?(/re/)
      #       do_something
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     if !x.match?(/re/)
      #       do_something
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     if x =~ /re/
      #       do_something(Regexp.last_match)
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     if x.match(/re/)
      #       do_something($~)
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     if /re/ === x
      #       do_something($~)
      #     end
      #   end
      class RegexpMatch < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.4

        # Constants are included in this list because it is unlikely that
        # someone will store `nil` as a constant and then use it for comparison
        TYPES_IMPLEMENTING_MATCH = %i[const regexp str sym].freeze
        MSG = 'Use `match?` instead of `%<current>s` when `MatchData` is not used.'

        def_node_matcher :match_method?, <<~PATTERN
          {
            (send _recv :match {regexp str sym})
            (send {regexp str sym} :match _)
          }
        PATTERN

        def_node_matcher :match_with_int_arg_method?, <<~PATTERN
          (send _recv :match _ (int ...))
        PATTERN

        def_node_matcher :match_operator?, <<~PATTERN
          (send !nil? {:=~ :!~} !nil?)
        PATTERN

        def_node_matcher :match_threequals?, <<~PATTERN
          (send (regexp (str _) {(regopt) (regopt _)}) :=== !nil?)
        PATTERN

        def match_with_lvasgn?(node)
          return false unless node.match_with_lvasgn_type?

          regexp, _rhs = *node
          regexp.to_regexp.named_captures.empty?
        end

        MATCH_NODE_PATTERN = <<~PATTERN
          {
            #match_method?
            #match_with_int_arg_method?
            #match_operator?
            #match_threequals?
            #match_with_lvasgn?
          }
        PATTERN

        def_node_matcher :match_node?, MATCH_NODE_PATTERN
        def_node_search :search_match_nodes, MATCH_NODE_PATTERN

        def_node_search :last_matches, <<~PATTERN
          {
            (send (const {nil? cbase} :Regexp) :last_match)
            (send (const {nil? cbase} :Regexp) :last_match _)
            ({back_ref nth_ref} _)
            (gvar #match_gvar?)
          }
        PATTERN

        def self.autocorrect_incompatible_with
          [ConstantRegexp]
        end

        def on_if(node)
          check_condition(node.condition)
        end

        def on_case(node)
          return if node.condition

          node.each_when do |when_node|
            when_node.each_condition do |condition|
              check_condition(condition)
            end
          end
        end

        private

        def check_condition(cond)
          match_node?(cond) do
            return if last_match_used?(cond)

            message = message(cond)
            add_offense(cond, message: message) do |corrector|
              autocorrect(corrector, cond)
            end
          end
        end

        def autocorrect(corrector, node)
          if match_method?(node) || match_with_int_arg_method?(node)
            corrector.replace(node.loc.selector, 'match?')
          elsif match_operator?(node) || match_threequals?(node)
            recv, oper, arg = *node
            correct_operator(corrector, recv, arg, oper)
          elsif match_with_lvasgn?(node)
            recv, arg = *node
            correct_operator(corrector, recv, arg)
          end
        end

        def message(node)
          format(MSG, current: node.loc.selector.source)
        end

        def last_match_used?(match_node)
          scope_root = scope_root(match_node)
          body = scope_root ? scope_body(scope_root) : match_node.ancestors.last

          range = range_to_search_for_last_matches(match_node, body, scope_root)

          find_last_match(body, range, scope_root)
        end

        def range_to_search_for_last_matches(match_node, body, scope_root)
          expression = if modifier_form?(match_node)
                         match_node.parent.if_branch.source_range
                       else
                         match_node.source_range
                       end

          match_node_pos = expression.begin_pos
          next_match_pos = next_match_pos(body, match_node_pos, scope_root)

          match_node_pos..next_match_pos
        end

        def next_match_pos(body, match_node_pos, scope_root)
          node = search_match_nodes(body).find do |match|
            begin_pos = if modifier_form?(match)
                          match.parent.if_branch.source_range.begin_pos
                        else
                          match.source_range.begin_pos
                        end

            begin_pos > match_node_pos && scope_root(match) == scope_root
          end

          node ? node.source_range.begin_pos : Float::INFINITY
        end

        def modifier_form?(match_node)
          match_node.parent.if_type? && match_node.parent.modifier_form?
        end

        def find_last_match(body, range, scope_root)
          last_matches(body).find do |ref|
            ref_pos = ref.source_range.begin_pos
            range.cover?(ref_pos) && scope_root(ref) == scope_root
          end
        end

        def scope_body(node)
          children = node.children
          case node.type
          when :module
            children[1]
          when :defs
            children[3]
          else
            children[2]
          end
        end

        def scope_root(node)
          node.each_ancestor.find do |ancestor|
            ancestor.type?(:def, :defs, :class, :module)
          end
        end

        def match_gvar?(sym)
          %i[$~ $MATCH $PREMATCH $POSTMATCH $LAST_PAREN_MATCH $LAST_MATCH_INFO].include?(sym)
        end

        def correct_operator(corrector, recv, arg, oper = nil)
          op_range = recv.source_range.end.join(arg.source_range.begin)

          replace_with_match_predicate_method(corrector, recv, arg, op_range)

          corrector.insert_after(arg, ')') unless op_range.source.end_with?('(')
          corrector.insert_before(recv, '!') if oper == :!~
        end

        def replace_with_match_predicate_method(corrector, recv, arg, op_range)
          if TYPES_IMPLEMENTING_MATCH.include?(recv.type)
            corrector.replace(op_range, '.match?(')
          elsif TYPES_IMPLEMENTING_MATCH.include?(arg.type)
            corrector.replace(op_range, '.match?(')
            swap_receiver_and_arg(corrector, recv, arg)
          else
            corrector.replace(op_range, '&.match?(')
          end
        end

        def swap_receiver_and_arg(corrector, recv, arg)
          corrector.replace(recv, arg.source)
          corrector.replace(arg, recv.source)
        end
      end
    end
  end
end
