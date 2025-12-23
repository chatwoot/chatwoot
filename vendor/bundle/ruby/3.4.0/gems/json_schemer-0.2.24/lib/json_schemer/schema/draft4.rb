# frozen_string_literal: true
module JSONSchemer
  module Schema
    class Draft4 < Base
      ID_KEYWORD = 'id'
      SUPPORTED_FORMATS = Set[
        'date-time',
        'email',
        'hostname',
        'ipv4',
        'ipv6',
        'uri',
        'regex'
      ].freeze

    private

      def id_keyword
        ID_KEYWORD
      end

      def supported_format?(format)
        SUPPORTED_FORMATS.include?(format)
      end

      def validate_exclusive_maximum(instance, exclusive_maximum, maximum)
        yield error(instance, 'exclusiveMaximum') if exclusive_maximum && instance.data >= maximum
      end

      def validate_exclusive_minimum(instance, exclusive_minimum, minimum)
        yield error(instance, 'exclusiveMinimum') if exclusive_minimum && instance.data <= minimum
      end

      def validate_integer(instance, &block)
        if !instance.data.is_a?(Integer)
          yield error(instance, 'integer')
          return
        end

        validate_numeric(instance, &block)
      end
    end
  end
end
