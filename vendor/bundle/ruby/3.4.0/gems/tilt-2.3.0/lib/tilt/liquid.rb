# frozen_string_literal: true
require_relative 'template'
require 'liquid'

module Tilt
  # Liquid template implementation. See:
  # http://liquidmarkup.org/
  #
  # Liquid is designed to be a *safe* template system and therefore
  # does not provide direct access to execuatable scopes. In order to
  # support a +scope+, the +scope+ must be able to represent itself
  # as a hash by responding to #to_h. If the +scope+ does not respond
  # to #to_h it will be ignored.
  #
  # LiquidTemplate does not support yield blocks.
  #
  # It's suggested that your program require 'liquid' at load
  # time when using this template engine.
  class LiquidTemplate < Template
    def prepare
      @options[:line_numbers] = true unless @options.has_key?(:line_numbers)
      @engine = ::Liquid::Template.parse(@data, @options)
    end

    def evaluate(scope, locs)
      locals = {}
      if scope.respond_to?(:to_h)
        scope.to_h.each{|k, v| locals[k.to_s] = v}
      end
      locs.each{|k, v| locals[k.to_s] = v}
      locals['yield'] = block_given? ? yield : ''
      locals['content'] = locals['yield']
      @engine.render(locals)
    end

    def allows_script?
      false
    end
  end
end
