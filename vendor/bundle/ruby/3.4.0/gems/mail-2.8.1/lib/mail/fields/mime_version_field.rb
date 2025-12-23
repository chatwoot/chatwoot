# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'
require 'mail/utilities'

module Mail
  class MimeVersionField < NamedStructuredField #:nodoc:
    NAME = 'Mime-Version'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      value = '1.0' if Utilities.blank?(value)
      super value, charset
    end

    def element
      @element ||= Mail::MimeVersionElement.new(value)
    end

    def version
      "#{element.major}.#{element.minor}"
    end

    def major
      element.major.to_i
    end

    def minor
      element.minor.to_i
    end

    def encoded
      "#{name}: #{version}\r\n"
    end

    def decoded
      version
    end
  end
end
