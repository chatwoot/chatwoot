# frozen_string_literal: true
module JSONSchemer
  module Schema
    class Draft6 < Base
      SUPPORTED_FORMATS = Set[
        'date-time',
        'email',
        'hostname',
        'ipv4',
        'ipv6',
        'uri',
        'uri-reference',
        'uri-template',
        'json-pointer',
        'regex'
      ].freeze

    private

      def supported_format?(format)
        SUPPORTED_FORMATS.include?(format)
      end
    end
  end
end
