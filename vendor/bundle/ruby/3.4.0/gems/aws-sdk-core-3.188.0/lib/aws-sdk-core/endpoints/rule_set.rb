# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class RuleSet
      def initialize(version:, service_id:, parameters:, rules:)
        @version = version
        @service_id = service_id
        @parameters = parameters
        @rules = RuleSet.rules_from_json(rules || [])
      end

      attr_reader :version
      attr_reader :service_id
      attr_reader :parameters
      attr_reader :rules

      def self.rules_from_json(rules_json)
        rules_json.each.with_object([]) do |rule, rules|
          if rule['type'] == 'endpoint'
            rules << EndpointRule.new(
              conditions: rule['conditions'],
              endpoint: rule['endpoint'],
              documentation: rule['documentation']
            )
          elsif rule['type'] == 'error'
            rules << ErrorRule.new(
              conditions: rule['conditions'],
              error: rule['error'],
              documentation: rule['documentation']
            )
          elsif rule['type'] == 'tree'
            rules << TreeRule.new(
              conditions: rule['conditions'],
              rules: rule['rules'],
              documentation: rule['documentation']
            )
          else
            # should not happen
            raise "Unknown endpoint rule type: #{rule}"
          end
        end
      end
    end
  end
end
