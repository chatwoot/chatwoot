# frozen_string_literal: true
require_relative 'erb'
require 'erubis'

module Tilt
  # Erubis template implementation. See:
  # http://www.kuwata-lab.com/erubis/
  #
  # ErubisTemplate supports the following additional options, which are not
  # passed down to the Erubis engine:
  #
  #   :engine_class   allows you to specify a custom engine class to use
  #                   instead of the default (which is ::Erubis::Eruby).
  #
  #   :escape_html    when true, ::Erubis::EscapedEruby will be used as
  #                   the engine class instead of the default. All content
  #                   within <%= %> blocks will be automatically html escaped.
  class ErubisTemplate < ERBTemplate
    def prepare
      @freeze_string_literals = !!@options.delete(:freeze)
      @outvar = @options.delete(:outvar) || '_erbout'
      @options[:preamble] = false
      @options[:postamble] = false
      @options[:bufvar] = @outvar
      engine_class = @options.delete(:engine_class)
      engine_class = ::Erubis::EscapedEruby if @options.delete(:escape_html)
      @engine = (engine_class || ::Erubis::Eruby).new(@data, @options)
    end

    def precompiled_preamble(locals)
      [super, "#{@outvar} = _buf = String.new"].join("\n")
    end

    def precompiled_postamble(locals)
      [@outvar, super].join("\n")
    end

    # Erubis doesn't have ERB's line-off-by-one under 1.9 problem.
    # Override and adjust back.
    def precompiled(locals)
      source, offset = super
      [source, offset - 1]
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end
