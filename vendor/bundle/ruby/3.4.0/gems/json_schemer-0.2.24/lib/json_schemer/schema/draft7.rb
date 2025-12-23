# frozen_string_literal: true
module JSONSchemer
  module Schema
    class Draft7 < Base
      SUPPORTED_FORMATS = Set[
        'date-time',
        'date',
        'time',
        'email',
        'idn-email',
        'hostname',
        'idn-hostname',
        'ipv4',
        'ipv6',
        'uri',
        'uri-reference',
        'iri',
        'iri-reference',
        'uri-template',
        'json-pointer',
        'relative-json-pointer',
        'regex'
      ].freeze

    private

      def supported_format?(format)
        SUPPORTED_FORMATS.include?(format)
      end
    end
  end
end
