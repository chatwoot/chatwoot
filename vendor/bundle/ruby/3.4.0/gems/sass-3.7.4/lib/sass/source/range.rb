module Sass::Source
  class Range
    # The starting position of the range in the document (inclusive).
    #
    # @return [Sass::Source::Position]
    attr_accessor :start_pos

    # The ending position of the range in the document (exclusive).
    #
    # @return [Sass::Source::Position]
    attr_accessor :end_pos

    # The file in which this source range appears. This can be nil if the file
    # is unknown or not yet generated.
    #
    # @return [String]
    attr_accessor :file

    # The importer that imported the file in which this source range appears.
    # This is nil for target ranges.
    #
    # @return [Sass::Importers::Base]
    attr_accessor :importer

    # @param start_pos [Sass::Source::Position] See \{#start_pos}
    # @param end_pos [Sass::Source::Position] See \{#end_pos}
    # @param file [String] See \{#file}
    # @param importer [Sass::Importers::Base] See \{#importer}
    def initialize(start_pos, end_pos, file, importer = nil)
      @start_pos = start_pos
      @end_pos = end_pos
      @file = file
      @importer = importer
    end

    # @return [String] A string representation of the source range.
    def inspect
      "(#{start_pos.inspect} to #{end_pos.inspect}#{" in #{@file}" if @file})"
    end
  end
end
