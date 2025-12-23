# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'
require 'mail/fields/parameter_hash'

module Mail
  class ContentDispositionField < NamedStructuredField #:nodoc:
    NAME = 'Content-Disposition'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      super ensure_filename_quoted(value), charset
    end

    def element
      @element ||= Mail::ContentDispositionElement.new(value)
    end

    def disposition_type
      element.disposition_type
    end

    def parameters
      @parameters = ParameterHash.new
      element.parameters.each { |p| @parameters.merge!(p) } unless element.parameters.nil?
      @parameters
    end

    def filename
      @filename ||= parameters['filename'] || parameters['name']
    end

    def encoded
      p = ";\r\n\s#{parameters.encoded}" if parameters.length > 0
      "#{name}: #{disposition_type}#{p}\r\n"
    end

    def decoded
      p = "; #{parameters.decoded}" if parameters.length > 0
      "#{disposition_type}#{p}"
    end
  end
end
