# frozen_string_literal: true

module RuboCop
  module Cop
    # This class does condition autocorrection
    class ConditionCorrector
      class << self
        def correct_negative_condition(corrector, node)
          condition = negated_condition(node)

          corrector.replace(node.loc.keyword, node.inverse_keyword)
          corrector.replace(condition, condition.children.first.source)
        end

        private

        def negated_condition(node)
          condition = node.condition
          condition = condition.children.first while condition.begin_type?
          condition
        end
      end
    end
  end
end
