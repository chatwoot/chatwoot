# frozen_string_literal: true

# This is a copy of https://github.com/jnunemaker/crack/blob/master/lib/crack/json.rb
# with date parsing removed
# Copyright (c) 2004-2008 David Heinemeier Hansson
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module WebMock
  module Util
    class JSON
      class ParseError < StandardError; end

      def self.parse(json)
        yaml = unescape(convert_json_to_yaml(json))
        YAML.load(yaml)
      rescue ArgumentError => e
        raise ParseError, "Invalid JSON string: #{yaml}, Error: #{e.inspect}"
      end

      protected
      def self.unescape(str)
        str.gsub(/\\u([0-9a-f]{4})/) { [$1.hex].pack("U") }
      end

      # Ensure that ":" and "," are always followed by a space
      def self.convert_json_to_yaml(json) #:nodoc:
        scanner, quoting, marks, times = StringScanner.new(json), false, [], []
        while scanner.scan_until(/(\\['"]|['":,\\]|\\.)/)
          case char = scanner[1]
          when '"', "'"
            if !quoting
              quoting = char
            elsif quoting == char
              quoting = false
            end
          when ":",","
              marks << scanner.pos - 1 unless quoting
          when "\\"
              scanner.skip(/\\/)
          end
        end

        if marks.empty?
          json.gsub(/\\\//, '/')
        else
          left_pos  = [-1].push(*marks)
          right_pos = marks << json.bytesize
          output    = []

          left_pos.each_with_index do |left, i|
            if json.respond_to?(:byteslice)
              output << json.byteslice(left.succ..right_pos[i])
            else
              output << json[left.succ..right_pos[i]]
            end
          end

          output = output * " "

          times.each { |i| output[i-1] = ' ' }
          output.gsub!(/\\\//, '/')
          output
        end
      end
    end
  end
end
