# frozen_string_literal: true

module Aws
  # @api private
  module Stubbing
    class StubData

      def initialize(operation)
        @rules = operation.output
        @pager = operation[:pager]
      end

      def stub(data = {})
        stub = EmptyStub.new(@rules).stub
        remove_paging_tokens(stub)
        remove_checksums(stub)
        apply_data(data, stub)
        stub
      end

      private

      def remove_checksums(stub)
        if @rules && @rules.shape.is_a?(Seahorse::Model::Shapes::StructureShape)
          @rules.shape.members.each do |key, member|
            if member.location == 'header' && member.location_name.start_with?('x-amz-checksum-')
              stub[key] = nil
            end
          end
        end
      end

      def remove_paging_tokens(stub)
        if @pager
          @pager.instance_variable_get("@tokens").keys.each do |path|
            if divide = (path[' || '] || path[' or '])
              path = path.split(divide)[0]
            end
            parts = path.split(/\b/)
            # if nested struct/expression, EmptyStub auto-pop "string"
            # currently not support remove "string" for nested/expression
            # as it requires reverse JMESPATH search
            stub[parts[0]] = nil if parts.size == 1
          end
          if more_results = @pager.instance_variable_get('@more_results')
            parts = more_results.split(/\b/)
            # if nested struct/expression, EmptyStub auto-pop false value
            # no further work needed
            stub[parts[0]] = false if parts.size == 1
          end
        end
      end

      def apply_data(data, stub)
        ParamValidator.new(@rules, validate_required: false, input: false).validate!(data)
        DataApplicator.new(@rules).apply_data(data, stub)
      end
    end
  end
end
