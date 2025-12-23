module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class RulesProvider
      def initialize(rule_set)
        @rule_set = rule_set
      end

      def resolve_endpoint(parameters)
        obj = resolve_rules(parameters)
        case obj
        when Endpoint
          obj
        when ArgumentError
          raise obj
        else
          raise ArgumentError, 'No endpoint could be resolved'
        end
      end

      private

      def resolve_rules(parameters)
        @rule_set.rules.each do |rule|
          output = rule.match(parameters)
          return output if output
        end
        nil
      end
    end
  end
end
