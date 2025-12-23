# frozen_string_literal: true
require 'json'
require 'sprockets/path_utils'

module Sprockets
  module SourceMapUtils
    extend self

    # Public: Transpose source maps into a standard format
    #
    # NOTE: Does not support index maps
    #
    # version => 3
    # file    => logical path
    # sources => relative from filename
    #
    #   Unnecessary attributes are removed
    #
    # Example
    #
    #     map
    #     #=> {
    #     #  "version"        => 3,
    #     #  "file"           => "stdin",
    #     #  "sourceRoot"     => "",
    #     #  "sourceContents" => "blah blah blah",
    #     #  "sources"        => [/root/logical/path.js],
    #     #  "names"          => [..],
    #     #}
    #     format_source_map(map, input)
    #     #=> {
    #     #  "version"        => 3,
    #     #  "file"           => "logical/path.js",
    #     #  "sources"        => ["path.js"],
    #     #  "names"          => [..],
    #     #}
    def format_source_map(map, input)
      filename      = input[:filename]
      load_path     = input[:load_path]
      load_paths    = input[:environment].config[:paths]
      mime_exts     = input[:environment].config[:mime_exts]
      pipeline_exts = input[:environment].config[:pipeline_exts]
      file          = PathUtils.split_subpath(load_path, filename)
      {
        "version"  => 3,
        "file"     => file,
        "mappings" => map["mappings"],
        "sources"  => map["sources"].map do |source|
          source = URIUtils.split_file_uri(source)[2] if source.start_with? "file://"
          source = PathUtils.join(File.dirname(filename), source) unless PathUtils.absolute_path?(source)
          _, source = PathUtils.paths_split(load_paths, source)
          source = PathUtils.relative_path_from(file, source)
          PathUtils.set_pipeline(source, mime_exts, pipeline_exts, :source)
        end,
        "names"    => map["names"]
      }
    end

    # Public: Concatenate two source maps.
    #
    # For an example, if two js scripts are concatenated, the individual source
    # maps for those files can be concatenated to map back to the originals.
    #
    # Examples
    #
    #     script3 = "#{script1}#{script2}"
    #     map3    = concat_source_maps(map1, map2)
    #
    # a - Source map hash
    # b - Source map hash
    #
    # Returns a new source map hash.
    def concat_source_maps(a, b)
      return a || b unless a && b
      a = make_index_map(a)
      b = make_index_map(b)

      offset = 0
      if a["sections"].count != 0 && !a["sections"].last["map"]["mappings"].empty?
        last_line_count = a["sections"].last["map"].delete("x_sprockets_linecount")
        offset += last_line_count || 1

        last_offset = a["sections"].last["offset"]["line"]
        offset += last_offset
      end

      a["sections"] += b["sections"].map do |section|
        {
          "offset" => section["offset"].merge({ "line" => section["offset"]["line"] + offset }),
          "map"    => section["map"].merge({
            "sources" => section["map"]["sources"].map do |source|
              PathUtils.relative_path_from(a["file"], PathUtils.join(File.dirname(b["file"]), source))
            end
          })
        }
      end
      a
    end

    # Public: Converts source map to index map
    #
    # Example:
    #
    #     map
    #     # => {
    #       "version"  => 3,
    #       "file"     => "..",
    #       "mappings" => "AAAA;AACA;..;AACA",
    #       "sources"  => [..],
    #       "names"    => [..]
    #     }
    #     make_index_map(map)
    #     # => {
    #       "version"  => 3,
    #       "file"     => "..",
    #       "sections" => [
    #         {
    #           "offset" => { "line" => 0, "column" => 0 },
    #           "map"    => {
    #             "version"  => 3,
    #             "file"     => "..",
    #             "mappings" => "AAAA;AACA;..;AACA",
    #             "sources"  => [..],
    #             "names"    => [..]
    #           }
    #         }
    #       ]
    #     }
    def make_index_map(map)
      return map if map.key? "sections"
      {
        "version"  => map["version"],
        "file"     => map["file"],
        "sections" => [
          {
            "offset" => { "line" => 0, "column" => 0 },
            "map"    => map
          }
        ]
      }
    end

    # Public: Combine two separate source map transformations into a single
    # mapping.
    #
    # Source transformations may happen in discrete steps producing separate
    # source maps. These steps can be combined into a single mapping back to
    # the source.
    #
    # For an example, CoffeeScript may transform a file producing a map. Then
    # Uglifier processes the result and produces another map. The CoffeeScript
    # map can be combined with the Uglifier map so the source lines of the
    # minified output can be traced back to the original CoffeeScript file.
    #
    # Returns a source map hash.
    def combine_source_maps(first, second)
      return second unless first

      _first  = decode_source_map(first)
      _second = decode_source_map(second)

      new_mappings = []

      _second[:mappings].each do |m|
        first_line = bsearch_mappings(_first[:mappings], m[:original])
        new_mappings << first_line.merge(generated: m[:generated]) if first_line
      end

      _first[:mappings] = new_mappings

      encode_source_map(_first)
    end

    # Public: Decompress source map
    #
    # Example:
    #
    #     decode_source_map(map)
    #     # => {
    #       version:  3,
    #       file:     "..",
    #       mappings: [
    #         { source: "..", generated: [0, 0], original: [0, 0], name: ".."}, ..
    #       ],
    #       sources:  [..],
    #       names:    [..]
    #     }
    #
    # map - Source map hash (v3 spec)
    #
    # Returns an uncompressed source map hash
    def decode_source_map(map)
      return nil unless map

      mappings, sources, names = [], [], []
      if map["sections"]
        map["sections"].each do |s|
          mappings += decode_source_map(s["map"])[:mappings].each do |m|
            m[:generated][0] += s["offset"]["line"]
            m[:generated][1] += s["offset"]["column"]
          end
          sources |= s["map"]["sources"]
          names   |= s["map"]["names"]
        end
      else
        mappings = decode_vlq_mappings(map["mappings"], sources: map["sources"], names: map["names"])
        sources  = map["sources"]
        names    = map["names"]
      end
      {
        version:  3,
        file:     map["file"],
        mappings: mappings,
        sources:  sources,
        names:    names
      }
    end

    # Public: Compress source map
    #
    # Example:
    #
    #     encode_source_map(map)
    #     # => {
    #       "version"  => 3,
    #       "file"     => "..",
    #       "mappings" => "AAAA;AACA;..;AACA",
    #       "sources"  => [..],
    #       "names"    => [..]
    #     }
    #
    # map - Source map hash (uncompressed)
    #
    # Returns a compressed source map hash according to source map spec v3
    def encode_source_map(map)
      return nil unless map
      {
        "version"  => map[:version],
        "file"     => map[:file],
        "mappings" => encode_vlq_mappings(map[:mappings], sources: map[:sources], names: map[:names]),
        "sources"  => map[:sources],
        "names"    => map[:names]
      }
    end

    # Public: Compare two source map offsets.
    #
    # Compatible with Array#sort.
    #
    # a - Array [line, column]
    # b - Array [line, column]
    #
    # Returns -1 if a < b, 0 if a == b and 1 if a > b.
    def compare_source_offsets(a, b)
      diff = a[0] - b[0]
      diff = a[1] - b[1] if diff == 0

      if diff < 0
        -1
      elsif diff > 0
        1
      else
        0
      end
    end

    # Public: Search Array of mappings for closest offset.
    #
    # mappings - Array of mapping Hash objects
    # offset  - Array [line, column]
    #
    # Returns mapping Hash object.
    def bsearch_mappings(mappings, offset, from = 0, to = mappings.size - 1)
      mid = (from + to) / 2

      if from > to
        return from < 1 ? nil : mappings[from-1]
      end

      case compare_source_offsets(offset, mappings[mid][:generated])
      when 0
        mappings[mid]
      when -1
        bsearch_mappings(mappings, offset, from, mid - 1)
      when 1
        bsearch_mappings(mappings, offset, mid + 1, to)
      end
    end

    # Public: Decode VLQ mappings and match up sources and symbol names.
    #
    # str     - VLQ string from 'mappings' attribute
    # sources - Array of Strings from 'sources' attribute
    # names   - Array of Strings from 'names' attribute
    #
    # Returns an Array of Mappings.
    def decode_vlq_mappings(str, sources: [], names: [])
      mappings = []

      source_id       = 0
      original_line   = 1
      original_column = 0
      name_id         = 0

      vlq_decode_mappings(str).each_with_index do |group, index|
        generated_column = 0
        generated_line   = index + 1

        group.each do |segment|
          generated_column += segment[0]
          generated = [generated_line, generated_column]

          if segment.size >= 4
            source_id        += segment[1]
            original_line    += segment[2]
            original_column  += segment[3]

            source   = sources[source_id]
            original = [original_line, original_column]
          else
            # TODO: Research this case
            next
          end

          if segment[4]
            name_id += segment[4]
            name     = names[name_id]
          end

          mapping = {source: source, generated: generated, original: original}
          mapping[:name] = name if name
          mappings << mapping
        end
      end

      mappings
    end

    # Public: Encode mappings Hash into a VLQ encoded String.
    #
    # mappings - Array of Hash mapping objects
    # sources  - Array of String sources (default: mappings source order)
    # names    - Array of String names (default: mappings name order)
    #
    # Returns a VLQ encoded String.
    def encode_vlq_mappings(mappings, sources: nil, names: nil)
      sources ||= mappings.map { |m| m[:source] }.uniq.compact
      names   ||= mappings.map { |m| m[:name] }.uniq.compact

      sources_index = Hash[sources.each_with_index.to_a]
      names_index   = Hash[names.each_with_index.to_a]

      source_id     = 0
      source_line   = 1
      source_column = 0
      name_id       = 0

      by_lines = mappings.group_by { |m| m[:generated][0] }

      ary = (1..(by_lines.keys.max || 1)).map do |line|
        generated_column = 0

        (by_lines[line] || []).map do |mapping|
          group = []
          group << mapping[:generated][1] - generated_column
          group << sources_index[mapping[:source]] - source_id
          group << mapping[:original][0] - source_line
          group << mapping[:original][1] - source_column
          group << names_index[mapping[:name]] - name_id if mapping[:name]

          generated_column = mapping[:generated][1]
          source_id        = sources_index[mapping[:source]]
          source_line      = mapping[:original][0]
          source_column    = mapping[:original][1]
          name_id          = names_index[mapping[:name]] if mapping[:name]

          group
        end
      end

      vlq_encode_mappings(ary)
    end

    # Public: Base64 VLQ encoding
    #
    # Adopted from ConradIrwin/ruby-source_map
    #   https://github.com/ConradIrwin/ruby-source_map/blob/master/lib/source_map/vlq.rb
    #
    # Resources
    #
    #   http://en.wikipedia.org/wiki/Variable-length_quantity
    #   https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
    #   https://github.com/mozilla/source-map/blob/master/lib/source-map/base64-vlq.js
    #
    VLQ_BASE_SHIFT = 5
    VLQ_BASE = 1 << VLQ_BASE_SHIFT
    VLQ_BASE_MASK = VLQ_BASE - 1
    VLQ_CONTINUATION_BIT = VLQ_BASE

    BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('')
    BASE64_VALUES = (0...64).inject({}) { |h, i| h[BASE64_DIGITS[i]] = i; h }

    # Public: Encode a list of numbers into a compact VLQ string.
    #
    # ary - An Array of Integers
    #
    # Returns a VLQ String.
    def vlq_encode(ary)
      result = []
      ary.each do |n|
        vlq = n < 0 ? ((-n) << 1) + 1 : n << 1
        loop do
          digit  = vlq & VLQ_BASE_MASK
          vlq  >>= VLQ_BASE_SHIFT
          digit |= VLQ_CONTINUATION_BIT if vlq > 0
          result << BASE64_DIGITS[digit]

          break unless vlq > 0
        end
      end
      result.join
    end

    # Public: Decode a VLQ string.
    #
    # str - VLQ encoded String
    #
    # Returns an Array of Integers.
    def vlq_decode(str)
      result = []
      shift = 0
      value = 0
      i = 0

      while i < str.size do
        digit = BASE64_VALUES[str[i]]
        raise ArgumentError unless digit
        continuation = (digit & VLQ_CONTINUATION_BIT) != 0
        digit &= VLQ_BASE_MASK
          value += digit << shift
        if continuation
          shift += VLQ_BASE_SHIFT
        else
          result << ((value & 1) == 1 ? -(value >> 1) : value >> 1)
          value = shift = 0
        end
        i += 1
      end
      result
    end

    # Public: Encode a mapping array into a compact VLQ string.
    #
    # ary - Two dimensional Array of Integers.
    #
    # Returns a VLQ encoded String separated by , and ;.
    def vlq_encode_mappings(ary)
      ary.map { |group|
        group.map { |segment|
          vlq_encode(segment)
        }.join(',')
      }.join(';')
    end

    # Public: Decode a VLQ string into mapping numbers.
    #
    # str - VLQ encoded String
    #
    # Returns an two dimensional Array of Integers.
    def vlq_decode_mappings(str)
      mappings = []

      str.split(';').each_with_index do |group, index|
        mappings[index] = []
        group.split(',').each do |segment|
          mappings[index] << vlq_decode(segment)
        end
      end

      mappings
    end
  end
end
