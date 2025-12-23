# frozen_string_literal: true
require_relative 'template'

module Tilt
  # Sass template implementation for generating CSS. See: https://sass-lang.com/
  #
  # Sass templates do not support object scopes, locals, or yield.
  class SassTemplate < StaticTemplate
    self.default_mime_type = 'text/css'

    begin
      require 'sass-embedded'
    # :nocov:
      require 'uri'

      private

      def _prepare_output
        ::Sass.compile_string(@data, **sass_options).css
      end

      def sass_options
        path = File.absolute_path(eval_file)
        path = '/' + path unless path.start_with?('/')
        @options[:url] = ::URI::File.build([nil, ::URI::DEFAULT_PARSER.escape(path)]).to_s
        @options[:syntax] = :indented
        @options
      end
    rescue LoadError => err
      begin
        require 'sassc'
        Engine = ::SassC::Engine
      rescue LoadError
        begin
          require 'sass'
          Engine = ::Sass::Engine
        rescue LoadError
          raise err
        end
      end

      private

      def _prepare_output
        Engine.new(@data, sass_options).render
      end

      def sass_options
        @options[:filename] = eval_file
        @options[:line] = @line
        @options[:syntax] = :sass
        @options
      end
    # :nocov:
    end
  end

  class ScssTemplate < SassTemplate
    self.default_mime_type = 'text/css'

    private

    def sass_options
      super
      @options[:syntax] = :scss
      @options
    end
  end
end
