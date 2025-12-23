# frozen_string_literal: true
require_relative 'template'
require 'builder'

module Tilt
  # Builder template implementation.
  class BuilderTemplate < Template
    self.default_mime_type = 'text/xml'

    def prepare
      @options[:indent] ||= 2
    end

    def evaluate(scope, locals, &block)
      if @data.respond_to?(:to_str)
        unless locals[:xml]
          locals = Hash[locals]
          locals[:xml] = xml_builder
        end
        return super
      end

      xml = locals[:xml] || xml_builder
      @data.call(xml)
      xml.target!
    end

    def precompiled_postamble(locals)
      "xml.target!"
    end

    def precompiled_template(locals)
      @data.to_str
    end

    private

    def xml_builder
      ::Builder::XmlMarkup.new(options)
    end
  end
end
