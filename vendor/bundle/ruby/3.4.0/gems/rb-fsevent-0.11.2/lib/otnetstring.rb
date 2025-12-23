# Copyright (c) 2011 Konstantin Haase
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require 'stringio'

module OTNetstring
  class Error < StandardError; end

  class << self
    def parse(io, encoding = 'internal', fallback_encoding = nil)
      fallback_encoding = io.encoding if io.respond_to? :encoding
      io = StringIO.new(io) if io.respond_to? :to_str
      length, byte = String.new, nil

      while byte.nil? || byte =~ /\d/
        length << byte if byte
        byte = io.read(1)
      end

      if length.size > 9
        raise Error, "#{length} is longer than 9 digits"
      elsif length !~ /\d+/
        raise Error, "Expected '#{byte}' to be a digit"
      end
      length = Integer(length)

      case byte
      when '#' then Integer io.read(length)
      when ',' then with_encoding io.read(length), encoding, fallback_encoding
      when '~' then
        raise Error, "nil has length of 0, #{length} given" unless length == 0
      when '!' then io.read(length) == 'true'
      when '[', '{'
        array = []
        start = io.pos
        array << parse(io, encoding, fallback_encoding) while io.pos - start < length
        raise Error, 'Nested element longer than container' if io.pos - start != length
        byte == "{" ? Hash[*array] : array
      else
        raise Error, "Unknown type '#{byte}'"
      end
    end

    def encode(obj, string_sep = ',')
      case obj
      when String   then with_encoding "#{obj.bytesize}#{string_sep}#{obj}", "binary"
      when Integer  then encode(obj.inspect, '#')
      when NilClass then "0~"
      when Array    then encode(obj.map { |e| encode(e) }.join, '[')
      when Hash     then encode(obj.map { |a,b| encode(a)+encode(b) }.join, '{')
      when FalseClass, TrueClass then encode(obj.inspect, '!')
      else raise Error, 'cannot encode %p' % obj
      end
    end

    private

    def with_encoding(str, encoding, fallback = nil)
      return str unless str.respond_to? :encode
      encoding = Encoding.find encoding if encoding.respond_to? :to_str
      encoding ||= fallback
      encoding ? str.encode(encoding) : str
    rescue EncodingError
      str.force_encoding(encoding)
    end
  end
end
