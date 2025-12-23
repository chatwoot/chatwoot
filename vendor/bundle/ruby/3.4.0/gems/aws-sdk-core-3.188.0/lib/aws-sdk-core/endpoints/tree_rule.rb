# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class TreeRule
      def initialize(type: 'tree', conditions:, rules:, documentation: nil)
        @type = type
        @conditions = Condition.from_json(conditions)
        @rules = RuleSet.rules_from_json(rules)
        @documentation = documentation
      end

      attr_reader :type
      attr_reader :conditions
      attr_reader :error
      attr_reader :documentation

      def match(parameters, assigned = {})
        assigns = assigned.dup
        matched = conditions.all? do |condition|
          output = condition.match?(parameters, assigns)
          assigns = assigns.merge(condition.assigned) if condition.assign
          output
        end
        resolve_rules(parameters, assigns) if matched
      end

      private

      def resolve_rules(parameters, assigns)
        @rules.each do |rule|
          output = rule.match(parameters, assigns)
          return output if output
        end
        nil
      end
    end
  end
end
