module Sass::Source
  class Map
    # A mapping from one source range to another. Indicates that `input` was
    # compiled to `output`.
    #
    # @!attribute input
    #   @return [Sass::Source::Range] The source range in the input document.
    #
    # @!attribute output
    #   @return [Sass::Source::Range] The source range in the output document.
    class Mapping < Struct.new(:input, :output)
      # @return [String] A string representation of the mapping.
      def inspect
        "#{input.inspect} => #{output.inspect}"
      end
    end

    # The mapping data ordered by the location in the target.
    #
    # @return [Array<Mapping>]
    attr_reader :data

    def initialize
      @data = []
    end

    # Adds a new mapping from one source range to another. Multiple invocations
    # of this method should have each `output` range come after all previous ranges.
    #
    # @param input [Sass::Source::Range]
    #   The source range in the input document.
    # @param output [Sass::Source::Range]
    #   The source range in the output document.
    def add(input, output)
      @data.push(Mapping.new(input, output))
    end

    # Shifts all output source ranges forward one or more lines.
    #
    # @param delta [Integer] The number of lines to shift the ranges forward.
    def shift_output_lines(delta)
      return if delta == 0
      @data.each do |m|
        m.output.start_pos.line += delta
        m.output.end_pos.line += delta
      end
    end

    # Shifts any output source ranges that lie on the first line forward one or
    # more characters on that line.
    #
    # @param delta [Integer] The number of characters to shift the ranges
    #   forward.
    def shift_output_offsets(delta)
      return if delta == 0
      @data.each do |m|
        break if m.output.start_pos.line > 1
        m.output.start_pos.offset += delta
        m.output.end_pos.offset += delta if m.output.end_pos.line > 1
      end
    end

    # Returns the standard JSON representation of the source map.
    #
    # If the `:css_uri` option isn't specified, the `:css_path` and
    # `:sourcemap_path` options must both be specified. Any options may also be
    # specified alongside the `:css_uri` option. If `:css_uri` isn't specified,
    # it will be inferred from `:css_path` and `:sourcemap_path` using the
    # assumption that the local file system has the same layout as the server.
    #
    # Regardless of which options are passed to this method, source stylesheets
    # that are imported using a non-default importer will only be linked to in
    # the source map if their importers implement
    # \{Sass::Importers::Base#public\_url\}.
    #
    # @option options :css_uri [String]
    #   The publicly-visible URI of the CSS output file.
    # @option options :css_path [String]
    #   The local path of the CSS output file.
    # @option options :sourcemap_path [String]
    #   The (eventual) local path of the sourcemap file.
    # @option options :type [Symbol]
    #   `:auto` (default),  `:file`, or `:inline`.
    # @return [String] The JSON string.
    # @raise [ArgumentError] If neither `:css_uri` nor `:css_path` and
    #   `:sourcemap_path` are specified.
    def to_json(options)
      css_uri, css_path, sourcemap_path =
        options[:css_uri], options[:css_path], options[:sourcemap_path]
      unless css_uri || (css_path && sourcemap_path)
        raise ArgumentError.new("Sass::Source::Map#to_json requires either " \
          "the :css_uri option or both the :css_path and :soucemap_path options.")
      end
      css_path &&= Sass::Util.pathname(File.absolute_path(css_path))
      sourcemap_path &&= Sass::Util.pathname(File.absolute_path(sourcemap_path))
      css_uri ||= Sass::Util.file_uri_from_path(
        Sass::Util.relative_path_from(css_path, sourcemap_path.dirname))

      result = "{\n"
      write_json_field(result, "version", 3, true)

      source_uri_to_id = {}
      id_to_source_uri = {}
      id_to_contents = {} if options[:type] == :inline
      next_source_id = 0
      line_data = []
      segment_data_for_line = []

      # These track data necessary for the delta coding.
      previous_target_line = nil
      previous_target_offset = 1
      previous_source_line = 1
      previous_source_offset = 1
      previous_source_id = 0

      @data.each do |m|
        file, importer = m.input.file, m.input.importer

        next unless importer

        if options[:type] == :inline
          source_uri = file
        else
          sourcemap_dir = sourcemap_path && sourcemap_path.dirname.to_s
          sourcemap_dir = nil if options[:type] == :file
          source_uri = importer.public_url(file, sourcemap_dir)
          next unless source_uri
        end

        current_source_id = source_uri_to_id[source_uri]
        unless current_source_id
          current_source_id = next_source_id
          next_source_id += 1

          source_uri_to_id[source_uri] = current_source_id
          id_to_source_uri[current_source_id] = source_uri

          if options[:type] == :inline
            id_to_contents[current_source_id] =
              importer.find(file, {}).instance_variable_get('@template')
          end
        end

        [
          [m.input.start_pos, m.output.start_pos],
          [m.input.end_pos, m.output.end_pos]
        ].each do |source_pos, target_pos|
          if previous_target_line != target_pos.line
            line_data.push(segment_data_for_line.join(",")) unless segment_data_for_line.empty?
            (target_pos.line - 1 - (previous_target_line || 0)).times {line_data.push("")}
            previous_target_line = target_pos.line
            previous_target_offset = 1
            segment_data_for_line = []
          end

          # `segment` is a data chunk for a single position mapping.
          segment = ""

          # Field 1: zero-based starting offset.
          segment << Sass::Util.encode_vlq(target_pos.offset - previous_target_offset)
          previous_target_offset = target_pos.offset

          # Field 2: zero-based index into the "sources" list.
          segment << Sass::Util.encode_vlq(current_source_id - previous_source_id)
          previous_source_id = current_source_id

          # Field 3: zero-based starting line in the original source.
          segment << Sass::Util.encode_vlq(source_pos.line - previous_source_line)
          previous_source_line = source_pos.line

          # Field 4: zero-based starting offset in the original source.
          segment << Sass::Util.encode_vlq(source_pos.offset - previous_source_offset)
          previous_source_offset = source_pos.offset

          segment_data_for_line.push(segment)

          previous_target_line = target_pos.line
        end
      end
      line_data.push(segment_data_for_line.join(","))
      write_json_field(result, "mappings", line_data.join(";"))

      source_names = []
      (0...next_source_id).each {|id| source_names.push(id_to_source_uri[id].to_s)}
      write_json_field(result, "sources", source_names)

      if options[:type] == :inline
        write_json_field(result, "sourcesContent",
          (0...next_source_id).map {|id| id_to_contents[id]})
      end

      write_json_field(result, "names", [])
      write_json_field(result, "file", css_uri)

      result << "\n}"
      result
    end

    private

    def write_json_field(out, name, value, is_first = false)
      out << (is_first ? "" : ",\n") <<
        "\"" <<
        Sass::Util.json_escape_string(name) <<
        "\": " <<
        Sass::Util.json_value_of(value)
    end
  end
end
