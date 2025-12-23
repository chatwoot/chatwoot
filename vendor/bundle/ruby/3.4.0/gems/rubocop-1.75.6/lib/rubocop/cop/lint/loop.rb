# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for uses of `begin...end while/until something`.
      #
      # @safety
      #   The cop is unsafe because behavior can change in some cases, including
      #   if a local variable inside the loop body is accessed outside of it, or if the
      #   loop body raises a `StopIteration` exception (which `Kernel#loop` rescues).
      #
      # @example
      #
      #   # bad
      #
      #   # using while
      #   begin
      #     do_something
      #   end while some_condition
      #
      #   # good
      #
      #   # while replacement
      #   loop do
      #     do_something
      #     break unless some_condition
      #   end
      #
      #   # bad
      #
      #   # using until
      #   begin
      #     do_something
      #   end until some_condition
      #
      #   # good
      #
      #   # until replacement
      #   loop do
      #     do_something
      #     break if some_condition
      #   end
      class Loop < Base
        extend AutoCorrector

        MSG = 'Use `Kernel#loop` with `break` rather than `begin/end/until`(or `while`).'

        def on_while_post(node)
          register_offense(node)
        end

        def on_until_post(node)
          register_offense(node)
        end

        private

        def register_offense(node)
          body = node.body

          add_offense(node.loc.keyword) do |corrector|
            corrector.replace(body.loc.begin, 'loop do')
            corrector.remove(keyword_and_condition_range(node))
            corrector.insert_before(body.loc.end, build_break_line(node))
          end
        end

        def keyword_and_condition_range(node)
          node.body.loc.end.end.join(node.source_range.end)
        end

        def build_break_line(node)
          conditional_keyword = node.while_post_type? ? 'unless' : 'if'
          "break #{conditional_keyword} #{node.condition.source}\n#{indent(node)}"
        end
      end
    end
  end
end
