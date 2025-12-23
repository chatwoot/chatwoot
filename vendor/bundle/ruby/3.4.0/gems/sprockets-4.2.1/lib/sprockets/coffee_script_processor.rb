# frozen_string_literal: true
require 'sprockets/autoload'
require 'sprockets/source_map_utils'

module Sprockets
  # Processor engine class for the CoffeeScript compiler.
  # Depends on the `coffee-script` and `coffee-script-source` gems.
  #
  # For more information see:
  #
  #   https://github.com/rails/ruby-coffee-script
  #
  module CoffeeScriptProcessor
    VERSION = '2'

    def self.cache_key
      @cache_key ||= "#{name}:#{Autoload::CoffeeScript::Source.version}:#{VERSION}".freeze
    end

    def self.call(input)
      data = input[:data]

      js, map = input[:cache].fetch([self.cache_key, data, input[:filename]]) do
        result = Autoload::CoffeeScript.compile(
          data,
          sourceMap: "v3",
          sourceFiles: [File.basename(input[:filename])],
          generatedFile: input[:filename]
        )
        [result['js'], JSON.parse(result['v3SourceMap'])]
      end

      map = SourceMapUtils.format_source_map(map, input)
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

      { data: js, map: map }
    end
  end
end
