# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'

module Mail
  class ContentLocationField < NamedStructuredField #:nodoc:
    NAME = 'Content-Location'

    def self.singular?
      true
    end

    def element
      @element ||= Mail::ContentLocationElement.new(value)
    end

    def location
      element.location
    end

    def encoded
      "#{name}: #{location}\r\n"
    end

    def decoded
      location
    end
  end
end
