# Copyright (c) 2004-2008 David Heinemeier Hansson
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'strscan'
require 'psych'

module Crack
  class JSON
    def self.parser_exceptions
      @parser_exceptions ||= [ArgumentError, Psych::SyntaxError]
    end

    if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0')
      def self.parse(json)
        yaml = unescape(convert_json_to_yaml(json))
        YAML.safe_load(yaml, permitted_classes: [Regexp, Date, Time])
      rescue *parser_exceptions
        raise ParseError, "Invalid JSON string"
      rescue Psych::DisallowedClass
        yaml
      end
    else # Ruby < 2.6
      def self.parse(json)
        yaml = unescape(convert_json_to_yaml(json))
        YAML.safe_load(yaml, [Regexp, Date, Time])
      rescue *parser_exceptions
        raise ParseError, "Invalid JSON string"
      rescue Psych::DisallowedClass
        yaml
      end
    end

    protected
      def self.unescape(str)
        # Force the encoding to be UTF-8 so we can perform regular expressions
        # on 1.9.2 without blowing up.
        # see http://stackoverflow.com/questions/1224204/ruby-mechanize-getting-force-encoding-exception for a similar issue
        str.force_encoding('UTF-8') if defined?(Encoding) && str.respond_to?(:force_encoding)
        str.gsub(/\\u0000/, "").gsub(/\\[u|U]([0-9a-fA-F]{4})/) { [$1.hex].pack("U") }
      end

      # matches YAML-formatted dates
      DATE_REGEX = /^\d{4}-\d{2}-\d{2}$|^\d{4}-\d{1,2}-\d{1,2}[T \t]+\d{1,2}:\d{2}:\d{2}(\.[0-9]*)?(([ \t]*)Z|[-+]\d{2}?(:\d{2})?)$/

      # Ensure that ":" and "," are always followed by a space
      def self.convert_json_to_yaml(json) #:nodoc:
        json = String.new(json) #can't modify a frozen string
        scanner, quoting, marks, pos, date_starts, date_ends = StringScanner.new(json), false, [], nil, [], []
        while scanner.scan_until(/(\\['"]|['":,\/\\]|\\.)/)
          case char = scanner[1]
          when '"', "'"
            if !quoting
              quoting = char
              pos = scanner.pos
            elsif quoting == char
              if json[pos..scanner.pos-2] =~ DATE_REGEX
                # found a date, track the exact positions of the quotes so we can remove them later.
                # oh, and increment them for each current mark, each one is an extra padded space that bumps
                # the position in the final YAML output
                total_marks = marks.size
                date_starts << pos+total_marks
                date_ends << scanner.pos+total_marks
              end
              quoting = false
            end
          when "/"
            if !quoting
              json[scanner.pos - 1] = "!ruby/regexp /"
              scanner.pos += 13
              scanner.scan_until(/\/[mix]*/)
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
          left_pos  = marks.clone.unshift(-1)
          right_pos = marks << json.length
          output    = []
          left_pos.each_with_index do |left, i|
            output << json[left.succ..right_pos[i]]
          end
          output = output * " "

          format_dates(output, date_starts, date_ends)
          output.gsub!(/\\\//, '/')
          output
        end
      end

      def self.format_dates(output, date_starts, date_ends)
        if YAML.constants.include?('Syck')
          (date_starts + date_ends).each { |i| output[i-1] = ' ' }
        else
          extra_chars_to_be_added = 0
          timestamp_marker = '!!timestamp '
          timestamp_marker_size = timestamp_marker.size

          date_starts.each do |i|
            output[i-2+extra_chars_to_be_added] = timestamp_marker
            extra_chars_to_be_added += timestamp_marker_size - 1
          end
        end
      end
  end
end
