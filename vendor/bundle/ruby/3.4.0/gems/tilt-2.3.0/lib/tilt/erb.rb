# frozen_string_literal: true
require_relative 'template'
require 'erb'

module Tilt
  # ERB template implementation. See:
  # http://www.ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html
  class ERBTemplate < Template
    SUPPORTS_KVARGS = ::ERB.instance_method(:initialize).parameters.assoc(:key) rescue false

    def prepare
      @freeze_string_literals = !!@options[:freeze]
      @outvar = @options[:outvar] || '_erbout'
      trim = case @options[:trim]
      when false
        nil
      when nil, true
        '<>'
      else
        @options[:trim]
      end
      @engine = if SUPPORTS_KVARGS
        ::ERB.new(@data, trim_mode: trim, eoutvar: @outvar)
      # :nocov:
      else
        ::ERB.new(@data, options[:safe], trim, @outvar)
      # :nocov:
      end
    end

    def precompiled_template(locals)
      source = @engine.src
      source
    end

    def precompiled_preamble(locals)
      <<-RUBY
        begin
          __original_outvar = #{@outvar} if defined?(#{@outvar})
          #{super}
      RUBY
    end

    def precompiled_postamble(locals)
      <<-RUBY
          #{super}
        ensure
          #{@outvar} = __original_outvar
        end
      RUBY
    end

    # ERB generates a line to specify the character coding of the generated
    # source in 1.9. Account for this in the line offset.
    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end

