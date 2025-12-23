# frozen_string_literal: true
require_relative 'template'
require 'asciidoctor'
# AsciiDoc see: http://asciidoc.org/

# Asciidoctor implementation for AsciiDoc see:
# http://asciidoctor.github.com/
#
# Asciidoctor is an open source, pure-Ruby processor for
# converting AsciiDoc documents or strings into HTML 5,
# DocBook 4.5 and other formats.
Tilt::AsciidoctorTemplate = Tilt::StaticTemplate.subclass do
  @options[:header_footer] = false if @options[:header_footer].nil?
  Asciidoctor.render(@data, @options)
end
