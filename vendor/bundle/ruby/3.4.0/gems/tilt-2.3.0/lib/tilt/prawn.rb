# frozen_string_literal: true
require_relative 'template'
require 'prawn'

module Tilt
  # Prawn template implementation. See: http://prawnpdf.org
  class PrawnTemplate < Template
    self.default_mime_type = 'application/pdf'
    
    def prepare
      @options[:page_size] = 'A4' unless @options.has_key?(:page_size)
      @options[:page_layout] = :portrait unless @options.has_key?(:page_layout)
      @engine = ::Prawn::Document.new(@options)
    end
    
    def evaluate(scope, locals, &block)
      pdf = @engine
      locals = locals.dup
      locals[:pdf] = pdf
      super
      pdf.render
    end
    
    def precompiled_template(locals)
      @data.to_str
    end
  end
end
