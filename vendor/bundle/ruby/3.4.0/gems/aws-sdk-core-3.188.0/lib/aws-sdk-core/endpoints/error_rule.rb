# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class ErrorRule < Rule
      def initialize(type: 'error', conditions:, error: nil, documentation: nil)
        @type = type
        @conditions = Condition.from_json(conditions)
        @error = error
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
        resolved_error(parameters, assigns) if matched
      end

      private

      def resolved_error(parameters, assigns)
        error = resolve_value(@error, parameters, assigns)
        ArgumentError.new(error)
      end
    end
  end
end
