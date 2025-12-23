# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/structured_field'

module Mail
  class NamedStructuredField < StructuredField #:nodoc:
    def initialize(value = nil, charset = nil)
      super self.class::NAME, value, charset
    end
  end
end
