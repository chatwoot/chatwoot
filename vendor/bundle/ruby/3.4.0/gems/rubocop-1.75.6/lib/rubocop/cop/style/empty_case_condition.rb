# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for case statements with an empty condition.
      #
      # @example
      #
      #   # bad:
      #   case
      #   when x == 0
      #     puts 'x is 0'
      #   when y == 0
      #     puts 'y is 0'
      #   else
      #     puts 'neither is 0'
      #   end
      #
      #   # good:
      #   if x == 0
      #     puts 'x is 0'
      #   elsif y == 0
      #     puts 'y is 0'
      #   else
      #     puts 'neither is 0'
      #   end
      #
      #   # good: (the case condition node is not empty)
      #   case n
      #   when 0
      #     puts 'zero'
      #   when 1
      #     puts 'one'
      #   else
      #     puts 'more'
      #   end
      class EmptyCaseCondition < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use empty `case` condition, instead use an `if` expression.'
        NOT_SUPPORTED_PARENT_TYPES = %i[return break next send csend].freeze

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def on_case(case_node)
          if case_node.condition || NOT_SUPPORTED_PARENT_TYPES.include?(case_node.parent&.type)
            return
          end

          branch_bodies = [*case_node.when_branches.map(&:body), case_node.else_branch].compact

          return if branch_bodies.any? do |body|
            body.return_type? || body.each_descendant.any?(&:return_type?)
          end

          add_offense(case_node.loc.keyword) { |corrector| autocorrect(corrector, case_node) }
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        private

        def autocorrect(corrector, case_node)
          when_branches = case_node.when_branches

          correct_case_when(corrector, case_node, when_branches)
          correct_when_conditions(corrector, when_branches)
        end

        def correct_case_when(corrector, case_node, when_nodes)
          case_range = case_node.loc.keyword.join(when_nodes.first.loc.keyword)

          corrector.replace(case_range, 'if')

          keep_first_when_comment(case_range, corrector)

          when_nodes[1..].each do |when_node|
            corrector.replace(when_node.loc.keyword, 'elsif')
          end
        end

        def correct_when_conditions(corrector, when_nodes)
          when_nodes.each do |when_node|
            conditions = when_node.conditions

            replace_then_with_line_break(corrector, conditions, when_node)

            next unless conditions.size > 1

            range = range_between(conditions.first.source_range.begin_pos,
                                  conditions.last.source_range.end_pos)

            corrector.replace(range, conditions.map(&:source).join(' || '))
          end
        end

        def keep_first_when_comment(case_range, corrector)
          indent = ' ' * case_range.column
          comments = processed_source.each_comment_in_lines(
            case_range.first_line...case_range.last_line
          ).map { |comment| "#{indent}#{comment.text}\n" }.join

          line_beginning = case_range.adjust(begin_pos: -case_range.column)
          corrector.insert_before(line_beginning, comments)
        end

        def replace_then_with_line_break(corrector, conditions, when_node)
          return unless when_node.parent.parent && when_node.then?

          range = range_between(conditions.last.source_range.end_pos, when_node.loc.begin.end_pos)

          corrector.replace(range, "\n")
        end
      end
    end
  end
end
