# frozen_string_literal: true
require_relative 'template'

module Tilt
  # The template source is evaluated as a Ruby string. The #{} interpolation
  # syntax can be used to generated dynamic output.
  class StringTemplate < Template
    def prepare
      hash = "TILT#{@data.hash.abs}"
      @freeze_string_literals = !!@options[:freeze]
      @code = String.new("<<#{hash}.chomp\n#{@data}\n#{hash}")
    end

    def precompiled_template(locals)
      @code
    end

    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end
