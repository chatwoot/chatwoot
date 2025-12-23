# frozen_string_literal: true
require 'sprockets/utils'

module Sprockets
  # `Compressing` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Compressing
    include Utils

    def compressors
      config[:compressors]
    end

    # Public: Register a new compressor `klass` at `sym` for `mime_type`.
    #
    # Registering a processor allows it to be looked up by `sym` later when
    # assigning a JavaScript or CSS compressor.
    #
    # Compressors only operate on JavaScript and CSS. If you want to compress a
    # different type of asset, use a processor instead.
    #
    # Examples
    #
    #     register_compressor 'text/css', :my_sass, MySassCompressor
    #     css_compressor = :my_sass
    #
    # mime_type - String MIME Type (one of: 'test/css' or 'application/javascript').
    # sym       - Symbol registration address.
    # klass     - The compressor class.
    #
    # Returns nothing.
    def register_compressor(mime_type, sym, klass)
      self.config = hash_reassoc(config, :compressors, mime_type) do |compressors|
        compressors[sym] = klass
        compressors
      end
    end

    # Return CSS compressor or nil if none is set
    def css_compressor
      if defined? @css_compressor
        @css_compressor
      end
    end

    # Assign a compressor to run on `text/css` assets.
    #
    # The compressor object must respond to `compress`.
    def css_compressor=(compressor)
      unregister_bundle_processor 'text/css', @css_compressor if defined? @css_compressor
      @css_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @css_compressor = klass = config[:compressors]['text/css'][compressor] || raise(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = proc { |input| compressor.compress(input[:data]) }
        @css_compressor = :css_compressor
      else
        @css_compressor = klass = compressor
      end

      register_bundle_processor 'text/css', klass
    end

    # Return JS compressor or nil if none is set
    def js_compressor
      if defined? @js_compressor
        @js_compressor
      end
    end

    # Assign a compressor to run on `application/javascript` assets.
    #
    # The compressor object must respond to `compress`.
    def js_compressor=(compressor)
      unregister_bundle_processor 'application/javascript', @js_compressor if defined? @js_compressor
      @js_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @js_compressor = klass = config[:compressors]['application/javascript'][compressor] || raise(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = proc { |input| compressor.compress(input[:data]) }
        @js_compressor = :js_compressor
      else
        @js_compressor = klass = compressor
      end

      register_bundle_processor 'application/javascript', klass
    end

    # Public: Checks if Gzip is enabled.
    def gzip?
      config[:gzip_enabled]
    end

    # Public: Checks if Gzip is disabled.
    def skip_gzip?
      !gzip?
    end

    # Public: Enable or disable the creation of Gzip files.
    #
    # To disable gzip generation set to a falsey value:
    #
    #     environment.gzip = false
    #
    # To enable set to a truthy value. By default zlib wil
    # be used to gzip assets. If you have the Zopfli gem
    # installed you can specify the zopfli algorithm to be used
    # instead:
    #
    #     environment.gzip = :zopfli
    #
    def gzip=(gzip)
      self.config = config.merge(gzip_enabled: gzip).freeze

      case gzip
      when false, nil
        self.unregister_exporter Exporters::ZlibExporter
        self.unregister_exporter Exporters::ZopfliExporter
      when :zopfli
        self.unregister_exporter Exporters::ZlibExporter
        self.register_exporter '*/*', Exporters::ZopfliExporter
      else
        self.unregister_exporter Exporters::ZopfliExporter
        self.register_exporter '*/*', Exporters::ZlibExporter
      end

      gzip
    end
  end
end
