# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # @api private
    #
    # Internal contains helpers used by the reference implementation.
    module Internal
      extend self

      def boolean?(value)
        value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
      end

      def valid_key?(key)
        key.instance_of?(String)
      end

      def numeric?(value)
        value.instance_of?(Integer) || value.instance_of?(Float)
      end

      def valid_simple_value?(value)
        value.instance_of?(String) || boolean?(value) || numeric?(value)
      end

      def valid_array_value?(value)
        return false unless value.is_a?(Array)
        return true if value.empty?

        case value.first
        when String
          value.all? { |v| v.instance_of?(String) }
        when TrueClass, FalseClass
          value.all? { |v| boolean?(v) }
        when Numeric
          value.all? { |v| numeric?(v) }
        else
          false
        end
      end

      def valid_value?(value)
        valid_simple_value?(value) || valid_array_value?(value)
      end

      def valid_attributes?(owner, kind, attrs)
        attrs.nil? || attrs.each do |k, v|
          if !valid_key?(k)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute key type #{k.class} on span '#{owner}'")
            return false
          elsif !valid_value?(v)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute value type #{v.class} for key '#{k}' on span '#{owner}'")
            return false
          end
        end

        true
      end
    end
  end
end
