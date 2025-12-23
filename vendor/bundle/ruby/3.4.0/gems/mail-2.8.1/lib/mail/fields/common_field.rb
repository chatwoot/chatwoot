# encoding: utf-8
# frozen_string_literal: true
require 'mail/constants'

module Mail
  class CommonField #:nodoc:
    def self.singular?
      false
    end

    def self.parse(*args)
      new(*args).tap(&:parse)
    end

    attr_accessor :name
    attr_reader :value
    attr_accessor :charset
    attr_reader :errors

    def initialize(name = nil, value = nil, charset = nil)
      @errors = []

      self.name = name
      self.value = value
      self.charset = charset || 'utf-8'
    end

    def singular?
      self.class.singular?
    end

    def value=(value)
      @element = nil
      @value = value.is_a?(Array) ? value : value.to_s
      parse
    end

    def parse
      tap(&:element)
    end

    def element
      nil
    end

    def to_s
      decoded.to_s
    end

    def default
      decoded
    end

    def decoded
      do_decode
    end

    def encoded
      do_encode
    end

    def responsible_for?(field_name)
      name.to_s.casecmp(field_name.to_s) == 0
    end

    private

    FILENAME_RE = /\b(filename|name)=([^;"\r\n]+\s[^;"\r\n]+)/
    def ensure_filename_quoted(value)
      if value.is_a?(String)
        value.sub FILENAME_RE, '\1="\2"'
      else
        value
      end
    end
  end
end
