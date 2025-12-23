# frozen_string_literal: true
module Sprockets
  module Preprocessors
    # Private: Adds a default map to assets when one is not present
    #
    # If the input file already has a source map, it effectively returns the original
    # result. Otherwise it maps 1 for 1 lines original to generated. This is needed
    # Because other generators run after might depend on having a valid source map
    # available.
    class DefaultSourceMap
      def call(input)
        result        = { data: input[:data] }
        map           = input[:metadata][:map]
        filename      = input[:filename]
        load_path     = input[:load_path]
        lines         = input[:data].lines.length
        basename      = File.basename(filename)
        mime_exts     = input[:environment].config[:mime_exts]
        pipeline_exts = input[:environment].config[:pipeline_exts]
        if map.nil? || map.empty?
          result[:map] = {
            "version"   => 3,
            "file"      => PathUtils.split_subpath(load_path, filename),
            "mappings"  => default_mappings(lines),
            "sources"   => [PathUtils.set_pipeline(basename, mime_exts, pipeline_exts, :source)],
            "names"     => []
          }
        else
          result[:map] = map
        end

        result[:map]["x_sprockets_linecount"] = lines
        return result
      end

      private

      def default_mappings(lines)
        if (lines == 0)
          ""
        elsif (lines == 1)
          "AAAA"
        else
          "AAAA;" + "AACA;"*(lines - 2) + "AACA"
        end
      end
    end
  end
end
