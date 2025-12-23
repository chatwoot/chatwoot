# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class Rule
      # Resolves a value that is a function, reference, or template string.
      def resolve_value(value, parameters, assigns)
        if value.is_a?(Hash) && value['fn']
          Function.new(fn: value['fn'], argv: value['argv'])
                  .call(parameters, assigns)
        elsif value.is_a?(Hash) && value['ref']
          Reference.new(ref: value['ref']).resolve(parameters, assigns)
        else
          Templater.resolve(value, parameters, assigns)
        end
      end
    end
  end
end
