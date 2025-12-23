# frozen_string_literal: true
require_relative 'template'
require 'radius'

module Tilt
  # Radius Template
  # http://github.com/jlong/radius/
  class RadiusTemplate < Template
    class ContextClass < Radius::Context
      attr_accessor :tilt_scope

      def tag_missing(name, attributes)
        tilt_scope.__send__(name)
      end

      def dup
        i = super
        i.tilt_scope = tilt_scope
        i
      end
    end

    def evaluate(scope, locals, &block)
      context = ContextClass.new
      context.tilt_scope = scope
      context.define_tag("yield", &block) if block
      locals.each do |tag, value|
        context.define_tag(tag) do
          value
        end
      end

      @options[:tag_prefix] = 'r' unless @options.has_key?(:tag_prefix)
      Radius::Parser.new(context, @options).parse(@data)
    end

    def allows_script?
      false
    end
  end
end
