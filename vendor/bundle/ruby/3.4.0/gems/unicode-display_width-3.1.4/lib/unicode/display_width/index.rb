# frozen_string_literal: true

require "zlib"
require_relative "constants"

module Unicode
  class DisplayWidth
    File.open(INDEX_FILENAME, "rb") do |file|
      serialized_data = Zlib::GzipReader.new(file).read
      serialized_data.force_encoding Encoding::BINARY
      INDEX = Marshal.load(serialized_data)
    end

    def self.decompress_index(index, level)
      index.flat_map{ |value|
        if level > 0
          if value.instance_of?(Array)
            value[15] ||= nil
            decompress_index(value, level - 1)
          else
            decompress_index([value] * 16, level - 1)
          end
        else
          if value.instance_of?(Array)
            value[15] ||= nil
            value
          else
            [value] * 16
          end
        end
      }
    end
  end
end
