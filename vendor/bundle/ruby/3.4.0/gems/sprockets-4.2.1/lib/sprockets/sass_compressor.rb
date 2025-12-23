# frozen_string_literal: true
require 'sprockets/autoload'
require 'sprockets/digest_utils'
require 'sprockets/source_map_utils'

module Sprockets
  # Public: Sass CSS minifier.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SassCompressor
  #
  # Or to pass options to the Sass::Engine class.
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SassCompressor.new({ ... })
  #
  class SassCompressor
    VERSION = '1'

    # Public: Return singleton instance with default options.
    #
    # Returns SassCompressor object.
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

    def initialize(options = {})
      @options = {
        syntax: :scss,
        cache: false,
        read_cache: false,
        style: :compressed
      }.merge(options).freeze
      @cache_key = "#{self.class.name}:#{Autoload::Sass::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}".freeze
    end

    def call(input)
      css, map = Autoload::Sass::Engine.new(
        input[:data],
        @options.merge(filename: input[:filename])
      ).render_with_sourcemap('')

      css = css.sub("/*# sourceMappingURL= */\n", '')

      map = SourceMapUtils.format_source_map(JSON.parse(map.to_json(css_uri: '')), input)
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

      { data: css, map: map }
    end
  end
end
