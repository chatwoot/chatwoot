# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks that the cyclomatic complexity of methods is not higher
      # than the configured maximum. The cyclomatic complexity is the number of
      # linearly independent paths through a method. The algorithm counts
      # decision points and adds one.
      #
      # An if statement (or unless or ?:) increases the complexity by one. An
      # else branch does not, since it doesn't add a decision point. The &&
      # operator (or keyword and) can be converted to a nested if statement,
      # and ||/or is shorthand for a sequence of ifs, so they also add one.
      # Loops can be said to have an exit condition, so they add one.
      # Blocks that are calls to builtin iteration methods
      # (e.g. `ary.map{...}`) also add one, others are ignored.
      #
      # @example
      #
      #   def each_child_node(*types)               # count begins: 1
      #     unless block_given?                     # unless: +1
      #       return to_enum(__method__, *types)
      #     end
      #
      #     children.each do |child|                # each{}: +1
      #       next unless child.is_a?(Node)         # unless: +1
      #
      #       yield child if types.empty? ||        # if: +1, ||: +1
      #                      types.include?(child.type)
      #     end
      #
      #     self
      #   end                                       # total: 6
      class CyclomaticComplexity < Base
        include MethodComplexity
        include Utils::IteratingBlock

        MSG = 'Cyclomatic complexity for `%<method>s` is too high. [%<complexity>d/%<max>d]'
        COUNTED_NODES = %i[if while until for csend block block_pass
                           rescue when in_pattern and or or_asgn and_asgn].freeze

        private

        def complexity_score_for(node)
          return 0 if iterating_block?(node) == false
          return 0 if node.csend_type? && discount_for_repeated_csend?(node)

          1
        end

        def count_block?(block)
          KNOWN_ITERATING_METHODS.include? block.method_name
        end
      end
    end
  end
end
