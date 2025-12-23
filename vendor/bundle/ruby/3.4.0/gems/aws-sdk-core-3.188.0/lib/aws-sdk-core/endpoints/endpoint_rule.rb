# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.    # @api private
    class EndpointRule < Rule
      def initialize(type: 'endpoint', conditions:, endpoint:,
                     documentation: nil)
        @type = type
        @conditions = Condition.from_json(conditions)
        @endpoint = endpoint
        @documentation = documentation
      end

      attr_reader :type
      attr_reader :conditions
      attr_reader :endpoint
      attr_reader :documentation

      def match(parameters, assigned = {})
        assigns = assigned.dup
        matched = conditions.all? do |condition|
          output = condition.match?(parameters, assigns)
          assigns = assigns.merge(condition.assigned) if condition.assign
          output
        end
        resolved_endpoint(parameters, assigns) if matched
      end

      def resolved_endpoint(parameters, assigns)
        Endpoint.new(
          url: resolve_value(@endpoint['url'], parameters, assigns),
          properties: resolve_properties(
            @endpoint['properties'] || {},
            parameters,
            assigns
          ),
          headers: resolve_headers(parameters, assigns)
        )
      end

      private

      def resolve_headers(parameters, assigns)
        (@endpoint['headers'] || {}).each.with_object({}) do |(key, arr), headers|
          headers[key] = []
          arr.each do |value|
            headers[key] << resolve_value(value, parameters, assigns)
          end
        end
      end

      def resolve_properties(obj, parameters, assigns)
        case obj
        when Hash
          obj.each.with_object({}) do |(key, value), hash|
            hash[key] = resolve_properties(value, parameters, assigns)
          end
        when Array
          obj.collect { |value| resolve_properties(value, parameters, assigns) }
        else
          if obj.is_a?(String)
            Templater.resolve(obj, parameters, assigns)
          else
            obj
          end
        end
      end
    end
  end
end
