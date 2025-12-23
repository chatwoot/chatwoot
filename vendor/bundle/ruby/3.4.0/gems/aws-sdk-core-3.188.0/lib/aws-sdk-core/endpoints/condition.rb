# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class Condition
      def initialize(fn:, argv:, assign: nil)
        @fn = Function.new(fn: fn, argv: argv)
        @assign = assign
        @assigned = {}
      end

      attr_reader :fn
      attr_reader :argv
      attr_reader :assign

      attr_reader :assigned

      def match?(parameters, assigns)
        output = @fn.call(parameters, assigns)
        @assigned = @assigned.merge({ @assign => output }) if @assign
        output
      end

      def self.from_json(conditions_json)
        conditions_json.each.with_object([]) do |condition, conditions|
          conditions << new(
            fn: condition['fn'],
            argv: condition['argv'],
            assign: condition['assign']
          )
        end
      end
    end
  end
end
