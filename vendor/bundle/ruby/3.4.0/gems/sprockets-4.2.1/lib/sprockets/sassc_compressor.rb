# frozen_string_literal: true
require 'sprockets/autoload'
require 'sprockets/source_map_utils'

module Sprockets
  # Public: Sass CSS minifier.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SasscCompressor
  #
  # Or to pass options to the Sass::Engine class.
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SasscCompressor.new({ ... })
  #
  class SasscCompressor
    # Public: Return singleton instance with default options.
    #
    # Returns SasscCompressor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def initialize(options = {})
      @options = {
        syntax: :scss,
        style: :compressed,
        source_map_contents: false,
        omit_source_map_url: true,
      }.merge(options).freeze
    end

    def call(input)
      # SassC requires the template to be modifiable
      input_data = input[:data].frozen? ? input[:data].dup : input[:data]
      engine = Autoload::SassC::Engine.new(input_data, @options.merge(filename: input[:filename], source_map_file: "#{input[:filename]}.map")) 
        
      css = engine.render.sub(/^\n^\/\*# sourceMappingURL=.*\*\/$/m, '')

      begin
        map = SourceMapUtils.format_source_map(JSON.parse(engine.source_map), input)
        map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)
      rescue SassC::NotRenderedError
        map = input[:metadata][:map]
      end

      { data: css, map: map }
    end
  end
end
