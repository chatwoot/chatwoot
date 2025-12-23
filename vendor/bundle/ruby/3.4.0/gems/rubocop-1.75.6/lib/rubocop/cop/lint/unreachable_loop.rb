# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for loops that will have at most one iteration.
      #
      # A loop that can never reach the second iteration is a possible error in the code.
      # In rare cases where only one iteration (or at most one iteration) is intended behavior,
      # the code should be refactored to use `if` conditionals.
      #
      # NOTE: Block methods that are used with ``Enumerable``s are considered to be loops.
      #
      # `AllowedPatterns` can be used to match against the block receiver in order to allow
      # code that would otherwise be registered as an offense (eg. `times` used not in an
      # `Enumerable` context).
      #
      # @example
      #   # bad
      #   while node
      #     do_something(node)
      #     node = node.parent
      #     break
      #   end
      #
      #   # good
      #   while node
      #     do_something(node)
      #     node = node.parent
      #   end
      #
      #   # bad
      #   def verify_list(head)
      #     item = head
      #     begin
      #       if verify(item)
      #         return true
      #       else
      #         return false
      #       end
      #     end while(item)
      #   end
      #
      #   # good
      #   def verify_list(head)
      #     item = head
      #     begin
      #       if verify(item)
      #         item = item.next
      #       else
      #         return false
      #       end
      #     end while(item)
      #
      #     true
      #   end
      #
      #   # bad
      #   def find_something(items)
      #     items.each do |item|
      #       if something?(item)
      #         return item
      #       else
      #         raise NotFoundError
      #       end
      #     end
      #   end
      #
      #   # good
      #   def find_something(items)
      #     items.each do |item|
      #       if something?(item)
      #         return item
      #       end
      #     end
      #     raise NotFoundError
      #   end
      #
      #   # bad
      #   2.times { raise ArgumentError }
      #
      # @example AllowedPatterns: ['(exactly|at_least|at_most)\(\d+\)\.times'] (default)
      #
      #   # good
      #   exactly(2).times { raise StandardError }
      class UnreachableLoop < Base
        include AllowedPattern

        MSG = 'This loop will have at most one iteration.'
        CONTINUE_KEYWORDS = %i[next redo].freeze

        def on_while(node)
          check(node)
        end
        alias on_until on_while
        alias on_while_post on_while
        alias on_until_post on_while
        alias on_for on_while

        def on_block(node)
          check(node) if loop_method?(node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def loop_method?(node)
          return false unless node.any_block_type?

          send_node = node.send_node
          loopable = send_node.enumerable_method? || send_node.enumerator_method? ||
                     send_node.method?(:loop)
          loopable && !matches_allowed_pattern?(send_node.source)
        end

        def check(node)
          statements = statements(node)
          break_statement = statements.find { |statement| break_statement?(statement) }
          return unless break_statement

          unless preceded_by_continue_statement?(break_statement) ||
                 conditional_continue_keyword?(break_statement)
            add_offense(node)
          end
        end

        def statements(node)
          body = node.body

          if body.nil?
            []
          elsif body.begin_type?
            body.children
          else
            [body]
          end
        end

        # @!method break_command?(node)
        def_node_matcher :break_command?, <<~PATTERN
          {
            return break
            (send
             {nil? (const {nil? cbase} :Kernel)}
             {:raise :fail :throw :exit :exit! :abort}
             ...)
          }
        PATTERN

        def break_statement?(node)
          return true if break_command?(node)

          case node.type
          when :begin, :kwbegin
            statements = *node
            break_statement = statements.find { |statement| break_statement?(statement) }
            break_statement && !preceded_by_continue_statement?(break_statement)
          when :if
            check_if(node)
          when :case, :case_match
            check_case(node)
          else
            false
          end
        end

        def check_if(node)
          if_branch = node.if_branch
          else_branch = node.else_branch
          if_branch && else_branch && break_statement?(if_branch) && break_statement?(else_branch)
        end

        def check_case(node)
          else_branch = node.else_branch
          return false unless else_branch
          return false unless break_statement?(else_branch)

          branches = if node.case_type?
                       node.when_branches
                     else
                       node.in_pattern_branches
                     end

          branches.all? { |branch| branch.body && break_statement?(branch.body) }
        end

        def preceded_by_continue_statement?(break_statement)
          break_statement.left_siblings.any? do |sibling|
            # Numblocks have the arguments count as a number or,
            # itblocks have `:it` symbol in the AST.
            next if sibling.is_a?(Integer) || sibling.is_a?(Symbol)
            next if sibling.loop_keyword? || loop_method?(sibling)

            sibling.each_descendant(*CONTINUE_KEYWORDS).any?
          end
        end

        def conditional_continue_keyword?(break_statement)
          or_node = break_statement.each_descendant(:or).to_a.last

          or_node && CONTINUE_KEYWORDS.include?(or_node.rhs.type)
        end
      end
    end
  end
end
