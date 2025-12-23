# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use `Kernel#loop` for infinite loops.
      #
      # @safety
      #   This cop is unsafe as the rule should not necessarily apply if the loop
      #   body might raise a `StopIteration` exception; contrary to other infinite
      #   loops, `Kernel#loop` silently rescues that and returns `nil`.
      #
      # @example
      #   # bad
      #   while true
      #     work
      #   end
      #
      #   # good
      #   loop do
      #     work
      #   end
      class InfiniteLoop < Base
        include Alignment
        extend AutoCorrector

        LEADING_SPACE = /\A(\s*)/.freeze

        MSG = 'Use `Kernel#loop` for infinite loops.'

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          @variables ||= []
          @variables.concat(scope.variables.values)
        end

        def on_while(node)
          while_or_until(node) if node.condition.truthy_literal?
        end

        def on_until(node)
          while_or_until(node) if node.condition.falsey_literal?
        end

        alias on_while_post on_while
        alias on_until_post on_until

        private

        def while_or_until(node)
          range = node.source_range
          # Not every `while true` and `until false` can be turned into a
          # `loop do` without further modification. The reason is that a
          # variable that's introduced inside a while/until loop is in scope
          # outside of that loop too, but a variable that's assigned for the
          # first time inside a block cannot be accessed after the block. In
          # those more complicated cases we don't report an offense.
          return if @variables.any? do |var|
            assigned_inside_loop?(var, range) &&
            !assigned_before_loop?(var, range) &&
            referenced_after_loop?(var, range)
          end

          add_offense(node.loc.keyword) { |corrector| autocorrect(corrector, node) }
        end

        def autocorrect(corrector, node)
          if node.type?(:while_post, :until_post)
            replace_begin_end_with_modifier(corrector, node)
          elsif node.modifier_form?
            replace_source(corrector, node.source_range, modifier_replacement(node))
          else
            replace_source(corrector, non_modifier_range(node), 'loop do')
          end
        end

        def assigned_inside_loop?(var, range)
          var.assignments.any? { |a| range.contains?(a.node.source_range) }
        end

        def assigned_before_loop?(var, range)
          b = range.begin_pos
          var.assignments.any? { |a| a.node.source_range.end_pos < b }
        end

        def referenced_after_loop?(var, range)
          e = range.end_pos
          var.references.any? { |r| r.node.source_range.begin_pos > e }
        end

        def replace_begin_end_with_modifier(corrector, node)
          corrector.replace(node.body.loc.begin, 'loop do')
          corrector.remove(node.body.loc.end.end.join(node.source_range.end))
        end

        def replace_source(corrector, range, replacement)
          corrector.replace(range, replacement)
        end

        def modifier_replacement(node)
          body = node.body
          if node.single_line?
            "loop { #{body.source} }"
          else
            indentation = body.source_range.source_line[LEADING_SPACE]

            ['loop do', body.source.gsub(/^/, indentation(node)), 'end'].join("\n#{indentation}")
          end
        end

        def non_modifier_range(node)
          start_range = node.loc.keyword.begin
          end_range = if node.do?
                        node.loc.begin.end
                      else
                        node.condition.source_range.end
                      end

          start_range.join(end_range)
        end
      end
    end
  end
end
