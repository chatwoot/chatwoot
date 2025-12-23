# -*- encoding : utf-8 -*-
# The MIT License (MIT)
#
# Copyright (c) 2011-2014 Hannes Georg
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

module URITemplate

  # An awesome little helper which helps iterating over a string.
  # Initialize with a regexp and pass a string to :each.
  # It will yield a string or a MatchData
  class RegexpEnumerator

    include Enumerable

    def initialize(regexp, options = {})
      @regexp = regexp
      @rest = options.fetch(:rest){ :yield }
    end

    def each(str)
      raise ArgumentError, "RegexpEnumerator#each expects a String, but got #{str.inspect}" unless str.kind_of? String
      return self.to_enum(:each,str) unless block_given?
      rest = str
      loop do
        m = @regexp.match(rest)
        if m.nil?
          if rest.size > 0
            yield rest
          end
          break
        end
        yield m.pre_match if m.pre_match.size > 0
        yield m
        if m[0].size == 0
          # obviously matches empty string, so post_match will equal rest
          # terminate or this will loop forever
          if m.post_match.size > 0
            yield m.post_match if @rest == :yield
            raise "#{@regexp.inspect} matched an empty string. The rest is #{m.post_match.inspect}." if @rest == :raise
          end
          break
        end
        rest = m.post_match
      end
      return self
    end

  end

  # This error will be raised whenever an object could not be converted to a param string.
  class Unconvertable < StandardError

    attr_reader :object

    def initialize(object)
      @object = object
      super("Could not convert the given object (#{Object.instance_method(:inspect).bind(@object).call() rescue '<????>'}) to a param since it doesn't respond to :to_param or :to_s.")
    end

  end

  # A collection of some utility methods.
  # The most methods are used to parse or generate uri-parameters.
  # I will use the escape_utils library if available, but runs happily without.
  #
  module Utils

    KCODE_UTF8 = (Regexp::KCODE_UTF8 rescue 0)

    # Bundles some string encoding methods.
    module StringEncoding

      # Methods which do actual encoding.
      module Encode
        # converts a string to ascii
        # 
        # @param str [String]
        # @return String
        # @visibility public
        def to_ascii(str)
          str.encode(Encoding::ASCII)
        end

        # converts a string to utf8
        # 
        # @param str [String]
        # @return String
        # @visibility public
        def to_utf8(str)
          str.encode(Encoding::UTF_8)
        end

        # enforces UTF8 encoding
        # 
        # @param str [String]
        # @return String
        # @visibility public
        def force_utf8(str)
          return str if str.encoding == Encoding::UTF_8
          str = str.dup if str.frozen?
          return str.force_encoding(Encoding::UTF_8)
        end

      end

      # Fallback methods to be used in pre 1.9 rubies.
      module Fallback

        def to_ascii(str)
          str
        end

        def to_utf8(str)
          str
        end

        def force_utf8(str)
          str
        end

      end

      # :nocov:
      if "".respond_to?(:encode)
        include Encode
      else
        include Fallback
      end
      # :nocov:

      private :force_utf8

    end

    module Escaping

      # A pure escaping module, which implements escaping methods in pure ruby.
      # The performance is acceptable, but could be better with escape_utils.
      module Pure

        # @private
        URL_ESCAPED = /([^A-Za-z0-9\-\._])/.freeze

        # @private
        URI_ESCAPED = /([^A-Za-z0-9!$&'()*+,.\/:;=?@\[\]_~])/.freeze

        # @private
        PCT = /%([0-9a-fA-F]{2})/.freeze

        def escape_url(s)
          to_utf8(s.to_s).gsub(URL_ESCAPED){
            '%'+$1.unpack('H2'*$1.bytesize).join('%').upcase
          }
        end

        def escape_uri(s)
          to_utf8(s.to_s).gsub(URI_ESCAPED){
            '%'+$1.unpack('H2'*$1.bytesize).join('%').upcase
          }
        end

        def unescape_url(s)
          force_utf8( to_ascii(s.to_s).gsub('+',' ').gsub(PCT){
            $1.to_i(16).chr
          } )
        end

        def unescape_uri(s)
          force_utf8( to_ascii(s.to_s).gsub(PCT){
            $1.to_i(16).chr
          })
        end

        def using_escape_utils?
          false
        end

      end

    if defined? EscapeUtils

      # A escaping module, which is backed by escape_utils.
      # The performance is good, espacially for strings with many escaped characters.
      module EscapeUtils

        include ::EscapeUtils

        def using_escape_utils?
          true
        end

        def escape_url(s)
          super(to_utf8(s.to_s)).gsub('+','%20')
        end

        def escape_uri(s)
          super(to_utf8(s.to_s))
        end

        def unescape_url(s)
          force_utf8(super(to_ascii(s.to_s)))
        end

        def unescape_uri(s)
          force_utf8(super(to_ascii(s.to_s)))
        end

      end

    end

    end

    include StringEncoding
    # :nocov:
    if Escaping.const_defined? :EscapeUtils
      include Escaping::EscapeUtils
      puts "Using escape_utils." if $VERBOSE
    else
      include Escaping::Pure
      puts "Not using escape_utils." if $VERBOSE
    end
    # :nocov:

    # Converts an object to a param value.
    # Tries to call :to_param and then :to_s on that object.
    # @raise Unconvertable if the object could not be converted.
    # @example
    #   URITemplate::Utils.object_to_param(5) #=> "5"
    #   o = Object.new
    #   def o.to_param
    #     "42"
    #   end
    #   URITemplate::Utils.object_to_param(o) #=> "42"
    def object_to_param(object)
      if object.respond_to? :to_param
        object.to_param
      elsif object.respond_to? :to_s
        object.to_s
      else
        raise Unconvertable.new(object) 
      end
    rescue NoMethodError
      raise Unconvertable.new(object)
    end

    # @api private
    # Should we use \u.... or \x.. in regexps?
    def use_unicode?
      eval('Regexp.compile("\u0020")') =~ " " rescue false
    end

    # Returns true when the given value is an array and it only consists of arrays with two items.
    # This useful when using a hash is not ideal, since it doesn't allow duplicate keys.
    # @example
    #   URITemplate::Utils.pair_array?( Object.new ) #=> false
    #   URITemplate::Utils.pair_array?( [] ) #=> true
    #   URITemplate::Utils.pair_array?( [1,2,3] ) #=> false
    #   URITemplate::Utils.pair_array?( [ ['a',1],['b',2],['c',3] ] ) #=> true
    #   URITemplate::Utils.pair_array?( [ ['a',1],['b',2],['c',3],[] ] ) #=> false
    def pair_array?(a)
      return false unless a.kind_of? Array
      return a.all?{|p| p.kind_of? Array and p.size == 2 }
    end

    # Turns the given value into a hash if it is an array of pairs.
    # Otherwise it returns the value.
    # You can test whether a value will be converted with {#pair_array?}.
    #
    # @example
    #   URITemplate::Utils.pair_array_to_hash( 'x' ) #=> 'x'
    #   URITemplate::Utils.pair_array_to_hash( [ ['a',1],['b',2],['c',3] ] ) #=> {'a'=>1,'b'=>2,'c'=>3}
    #   URITemplate::Utils.pair_array_to_hash( [ ['a',1],['a',2],['a',3] ] ) #=> {'a'=>3}
    #
    # @example Carful vs. Ignorant
    #   URITemplate::Utils.pair_array_to_hash( [ ['a',1],'foo','bar'], false ) #UNDEFINED!
    #   URITemplate::Utils.pair_array_to_hash( [ ['a',1],'foo','bar'], true )  #=> [ ['a',1], 'foo', 'bar']
    #
    # @param x the value to convert
    # @param careful [true,false] wheter to check every array item. Use this when you expect array with subarrays which are not pairs. Setting this to false however improves runtime by ~30% even with comparetivly short arrays.
    def pair_array_to_hash(x, careful = false )
      if careful ? pair_array?(x) : (x.kind_of?(Array) and ( x.empty? or x.first.kind_of?(Array) ) )
        return Hash[ x ]
      else
        return x
      end
    end

    extend self

    # @api privat
    def pair_array_to_hash2(x)
      c = {}
      result = []

      x.each do | (k,v) |
        e = c[k]
        if !e
          result << c[k] = [k,v]
        else
          e[1] = [e[1]] unless e[1].kind_of? Array
          e[1] << v
        end
      end

      return result
    end

    # @api private
    def compact_regexp(rx)
      rx.split("\n").map(&:strip).join
    end

  end

end
