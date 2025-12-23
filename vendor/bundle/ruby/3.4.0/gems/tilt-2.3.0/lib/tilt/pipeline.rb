# frozen_string_literal: true
require_relative 'template'

module Tilt
  # Superclass used for pipeline templates.  Should not be used directly.
  class Pipeline < Template
    def prepare
      @pipeline = self.class::TEMPLATES.inject(proc{|*| data}) do |data, (klass, options)|
        proc do |s,l,&sb|
          klass.new(file, line, options, &proc{|*| data.call(s, l, &sb)}).render(s, l, &sb)
        end
      end
    end

    def evaluate(scope, locals, &block)
      @pipeline.call(scope, locals, &block)
    end
  end
end
