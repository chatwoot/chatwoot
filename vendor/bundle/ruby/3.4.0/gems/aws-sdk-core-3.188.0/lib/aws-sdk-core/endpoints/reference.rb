# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class Reference
      def initialize(ref:)
        @ref = ref
      end

      attr_reader :ref

      def resolve(parameters, assigns)
        if parameters.class.singleton_class::PARAM_MAP.key?(@ref)
          member_name = parameters.class.singleton_class::PARAM_MAP[@ref]
          parameters[member_name]
        elsif assigns.key?(@ref)
          assigns[@ref]
        else
          raise ArgumentError,
                "Reference #{@ref} is not a param or an assigned value."
        end
      end
    end
  end
end
