# frozen_string_literal: true
require_relative 'template'
require 'erubi'

module Tilt
  # Erubi (a simplified version of Erubis) template implementation.
  # See https://github.com/jeremyevans/erubi
  #
  # ErubiTemplate supports the following additional options, in addition
  # to the options supported by the Erubi engine:
  #
  # :engine_class :: allows you to specify a custom engine class to use
  #                  instead of the default (which is ::Erubi::Engine).
  class ErubiTemplate < Template
    def prepare
      @options[:preamble] = false
      @options[:postamble] = false
      @options[:ensure] = true

      engine_class = @options[:engine_class] || Erubi::Engine

      # If :freeze option is given, the intent is to setup frozen string
      # literals in the template.  So enable frozen string literals in the
      # code Tilt generates if the :freeze option is given.
      if @freeze_string_literals = !!@options[:freeze]
        # Passing the :freeze option to Erubi sets the
        # frozen-string-literal magic comment, which doesn't have an effect
        # with Tilt as Tilt wraps the resulting code.  Worse, the magic
        # comment appearing not at the top of the file can cause a warning.
        # So remove the :freeze option before passing to Erubi.
        @options.delete(:freeze)

        # Erubi by default appends .freeze to template literals on Ruby 2.1+,
        # but that is not necessary and slows down code when Tilt is using
        # frozen string literals, so pass the :freeze_template_literals
        # option to not append .freeze.
        @options[:freeze_template_literals] = false
      end

      @engine = engine_class.new(@data, @options)
      @outvar = @engine.bufvar
      @src = @engine.src

      @engine
    end

    def precompiled_template(locals)
      @src
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end
