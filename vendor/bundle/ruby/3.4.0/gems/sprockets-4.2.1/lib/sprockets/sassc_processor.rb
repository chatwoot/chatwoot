# frozen_string_literal: true
require 'rack/utils'
require 'sprockets/autoload'
require 'sprockets/source_map_utils'
require 'uri'

module Sprockets
  # Processor engine class for the SASS/SCSS compiler. Depends on the `sassc` gem.
  #
  # For more information see:
  #
  #   https://github.com/sass/sassc-ruby
  #   https://github.com/sass/sassc-rails
  #
  class SasscProcessor

    # Internal: Defines default sass syntax to use. Exposed so the ScsscProcessor
    # may override it.
    def self.syntax
      :sass
    end

    # Public: Return singleton instance with default options.
    #
    # Returns SasscProcessor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    def initialize(options = {}, &block)
      @cache_version = options[:cache_version]
      @cache_key = "#{self.class.name}:#{VERSION}:#{Autoload::SassC::VERSION}:#{@cache_version}".freeze
      @importer_class = options[:importer]
      @sass_config = options[:sass_config] || {}
      @functions = Module.new do
        include Functions
        include options[:functions] if options[:functions]
        class_eval(&block) if block_given?
      end
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = engine_options(input, context)
      engine = Autoload::SassC::Engine.new(input[:data], options)

      css = Utils.module_include(Autoload::SassC::Script::Functions, @functions) do
        engine.render.sub(/^\n^\/\*# sourceMappingURL=.*\*\/$/m, '')
      end

      begin
        map = SourceMapUtils.format_source_map(JSON.parse(engine.source_map), input)
        map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

        engine.dependencies.each do |dependency|
          context.metadata[:dependencies] << URIUtils.build_file_digest_uri(dependency.filename)
        end
      rescue SassC::NotRenderedError
        map = input[:metadata][:map]
      end

      context.metadata.merge(data: css, map: map)
    end

    private

    def merge_options(options)
      defaults = @sass_config.dup

      if load_paths = defaults.delete(:load_paths)
        options[:load_paths] += load_paths
      end

      options.merge!(defaults)
      options
    end

    # Public: Functions injected into Sass context during Sprockets evaluation.
    #
    # This module may be extended to add global functionality to all Sprockets
    # Sass environments. Though, scoping your functions to just your environment
    # is preferred.
    #
    # module Sprockets::SasscProcessor::Functions
    #   def asset_path(path, options = {})
    #   end
    # end
    #
    module Functions
      # Public: Generate a url for asset path.
      #
      # Default implementation is deprecated. Currently defaults to
      # Context#asset_path.
      #
      # Will raise NotImplementedError in the future. Users should provide their
      # own base implementation.
      #
      # Returns a SassC::Script::Value::String.
      def asset_path(path, options = {})
        path = path.value

        path, _, query, fragment = URI.split(path)[5..8]
        path     = sprockets_context.asset_path(path, options)
        query    = "?#{query}" if query
        fragment = "##{fragment}" if fragment

        Autoload::SassC::Script::Value::String.new("#{path}#{query}#{fragment}", :string)
      end

      # Public: Generate a asset url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def asset_url(path, options = {})
        Autoload::SassC::Script::Value::String.new("url(#{asset_path(path, options).value})")
      end

      # Public: Generate url for image path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def image_path(path)
        asset_path(path, type: :image)
      end

      # Public: Generate a image url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def image_url(path)
        asset_url(path, type: :image)
      end

      # Public: Generate url for video path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def video_path(path)
        asset_path(path, type: :video)
      end

      # Public: Generate a video url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def video_url(path)
        asset_url(path, type: :video)
      end

      # Public: Generate url for audio path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def audio_path(path)
        asset_path(path, type: :audio)
      end

      # Public: Generate a audio url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def audio_url(path)
        asset_url(path, type: :audio)
      end

      # Public: Generate url for font path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def font_path(path)
        asset_path(path, type: :font)
      end

      # Public: Generate a font url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def font_url(path)
        asset_url(path, type: :font)
      end

      # Public: Generate url for javascript path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def javascript_path(path)
        asset_path(path, type: :javascript)
      end

      # Public: Generate a javascript url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def javascript_url(path)
        asset_url(path, type: :javascript)
      end

      # Public: Generate url for stylesheet path.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def stylesheet_path(path)
        asset_path(path, type: :stylesheet)
      end

      # Public: Generate a stylesheet url() link.
      #
      # path - SassC::Script::Value::String URL path
      #
      # Returns a SassC::Script::Value::String.
      def stylesheet_url(path)
        asset_url(path, type: :stylesheet)
      end

      # Public: Generate a data URI for asset path.
      #
      # path - SassC::Script::Value::String logical asset path
      #
      # Returns a SassC::Script::Value::String.
      def asset_data_url(path)
        url = sprockets_context.asset_data_uri(path.value)
        Autoload::SassC::Script::Value::String.new("url(" + url + ")")
      end

      protected
        # Public: The Environment.
        #
        # Returns Sprockets::Environment.
        def sprockets_environment
          options[:sprockets][:environment]
        end

        # Public: Mutatable set of dependencies.
        #
        # Returns a Set.
        def sprockets_dependencies
          options[:sprockets][:dependencies]
        end

        # Deprecated: Get the Context instance. Use APIs on
        # sprockets_environment or sprockets_dependencies directly.
        #
        # Returns a Context instance.
        def sprockets_context
          options[:sprockets][:context]
        end

    end

    def engine_options(input, context)
      merge_options({
        filename: input[:filename],
        syntax: self.class.syntax,
        load_paths: input[:environment].paths,
        importer: @importer_class,
        source_map_contents: false,
        source_map_file: "#{input[:filename]}.map",
        omit_source_map_url: true,
        sprockets: {
          context: context,
          environment: input[:environment],
          dependencies: context.metadata[:dependencies]
        }
      })
    end
  end


  class ScsscProcessor < SasscProcessor
    def self.syntax
      :scss
    end
  end
end
