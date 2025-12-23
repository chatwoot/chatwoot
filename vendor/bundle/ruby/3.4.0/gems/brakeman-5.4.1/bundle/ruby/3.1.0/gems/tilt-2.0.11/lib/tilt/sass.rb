require 'tilt/template'

module Tilt
  # Sass template implementation. See:
  # http://haml.hamptoncatlin.com/
  #
  # Sass templates do not support object scopes, locals, or yield.
  class SassTemplate < Template
    self.default_mime_type = 'text/css'

    begin
      require 'sass-embedded'
      require 'uri'
      Engine = nil
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
    end

    def prepare
      @engine = unless Engine.nil?
                  Engine.new(data, sass_options)
                end
    end

    def evaluate(scope, locals, &block)
      @output ||= if @engine.nil?
                    ::Sass.compile_string(data, **sass_embedded_options).css
                  else
                    @engine.render
                  end
    end

    def allows_script?
      false
    end

  private
    def eval_file_url
      path = File.absolute_path(eval_file)
      path = '/' + path unless path.start_with?('/')
      ::URI::File.build([nil, ::URI::DEFAULT_PARSER.escape(path)]).to_s
    end

    def sass_embedded_options
      options.merge(:url => eval_file_url, :syntax => :indented)
    end

    def sass_options
      options.merge(:filename => eval_file, :line => line, :syntax => :sass)
    end
  end

  # Sass's new .scss type template implementation.
  class ScssTemplate < SassTemplate
    self.default_mime_type = 'text/css'

  private
    def sass_embedded_options
      options.merge(:url => eval_file_url, :syntax => :scss)
    end

    def sass_options
      options.merge(:filename => eval_file, :line => line, :syntax => :scss)
    end
  end

end

