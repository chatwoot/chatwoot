# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/unstructured_field'

module Mail
  # The field names of any optional-field MUST NOT be identical to any
  # field name specified elsewhere in this standard.
  #
  # optional-field  =       field-name ":" unstructured CRLF
  class OptionalField < UnstructuredField #:nodoc:
    private
      def do_encode
        "#{wrapped_value}\r\n"
      end
  end
end
