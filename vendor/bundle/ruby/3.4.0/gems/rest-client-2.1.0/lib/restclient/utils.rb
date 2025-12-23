require 'http/accept'

module RestClient
  # Various utility methods
  module Utils

    # Return encoding from an HTTP header hash.
    #
    # We use the RFC 7231 specification and do not impose a default encoding on
    # text. This differs from the older RFC 2616 behavior, which specifies
    # using ISO-8859-1 for text/* content types without a charset.
    #
    # Strings will use the default encoding when this method returns nil. This
    # default is likely to be UTF-8 for Ruby >= 2.0
    #
    # @param headers [Hash<Symbol,String>]
    #
    # @return [String, nil] Return the string encoding or nil if no header is
    #   found.
    #
    # @example
    #   >> get_encoding_from_headers({:content_type => 'text/plain; charset=UTF-8'})
    #   => "UTF-8"
    #
    def self.get_encoding_from_headers(headers)
      type_header = headers[:content_type]
      return nil unless type_header

      # TODO: remove this hack once we drop support for Ruby 2.0
      if RUBY_VERSION.start_with?('2.0')
        _content_type, params = deprecated_cgi_parse_header(type_header)

        if params.include?('charset')
          return params.fetch('charset').gsub(/(\A["']*)|(["']*\z)/, '')
        end

      else

        begin
          _content_type, params = cgi_parse_header(type_header)
        rescue HTTP::Accept::ParseError
          return nil
        else
          params['charset']
        end
      end
    end

    # Parse a Content-Type like header.
    #
    # Return the main content-type and a hash of params.
    #
    # @param [String] line
    # @return [Array(String, Hash)]
    #
    def self.cgi_parse_header(line)
      types = HTTP::Accept::MediaTypes.parse(line)

      if types.empty?
        raise HTTP::Accept::ParseError.new("Found no types in header line")
      end

      [types.first.mime_type, types.first.parameters]
    end

    # Parse semi-colon separated, potentially quoted header string iteratively.
    #
    # @private
    #
    # @deprecated This method is deprecated and only exists to support Ruby
    #   2.0, which is not supported by HTTP::Accept.
    #
    # @todo remove this method when dropping support for Ruby 2.0
    #
    def self._cgi_parseparam(s)
      return enum_for(__method__, s) unless block_given?

      while s[0] == ';'
        s = s[1..-1]
        ends = s.index(';')
        while ends && ends > 0 \
              && (s[0...ends].count('"') -
                  s[0...ends].scan('\"').count) % 2 != 0
          ends = s.index(';', ends + 1)
        end
        if ends.nil?
          ends = s.length
        end
        f = s[0...ends]
        yield f.strip
        s = s[ends..-1]
      end
      nil
    end

    # Parse a Content-Type like header.
    #
    # Return the main content-type and a hash of options.
    #
    # This method was ported directly from Python's cgi.parse_header(). It
    # probably doesn't read or perform particularly well in ruby.
    # https://github.com/python/cpython/blob/3.4/Lib/cgi.py#L301-L331
    #
    # @param [String] line
    # @return [Array(String, Hash)]
    #
    # @deprecated This method is deprecated and only exists to support Ruby
    #   2.0, which is not supported by HTTP::Accept.
    #
    # @todo remove this method when dropping support for Ruby 2.0
    #
    def self.deprecated_cgi_parse_header(line)
      parts = _cgi_parseparam(';' + line)
      key = parts.next
      pdict = {}

      begin
        while (p = parts.next)
          i = p.index('=')
          if i
            name = p[0...i].strip.downcase
            value = p[i+1..-1].strip
            if value.length >= 2 && value[0] == '"' && value[-1] == '"'
              value = value[1...-1]
              value = value.gsub('\\\\', '\\').gsub('\\"', '"')
            end
            pdict[name] = value
          end
        end
      rescue StopIteration
      end

      [key, pdict]
    end

    # Serialize a ruby object into HTTP query string parameters.
    #
    # There is no standard for doing this, so we choose our own slightly
    # idiosyncratic format. The output closely matches the format understood by
    # Rails, Rack, and PHP.
    #
    # If you don't want handling of complex objects and only want to handle
    # simple flat hashes, you may want to use `URI.encode_www_form` instead,
    # which implements HTML5-compliant URL encoded form data.
    #
    # @param [Hash,ParamsArray] object The object to serialize
    #
    # @return [String] A string appropriate for use as an HTTP query string
    #
    # @see {flatten_params}
    #
    # @see URI.encode_www_form
    #
    # @see See also Object#to_query in ActiveSupport
    # @see http://php.net/manual/en/function.http-build-query.php
    #   http_build_query in PHP
    # @see See also Rack::Utils.build_nested_query in Rack
    #
    # Notable differences from the ActiveSupport implementation:
    #
    # - Empty hash and empty array are treated the same as nil instead of being
    #   omitted entirely from the output. Rather than disappearing, they will
    #   appear to be nil instead.
    #
    # It's most common to pass a Hash as the object to serialize, but you can
    # also use a ParamsArray if you want to be able to pass the same key with
    # multiple values and not use the rack/rails array convention.
    #
    # @since 2.0.0
    #
    # @example Simple hashes
    #   >> encode_query_string({foo: 123, bar: 456})
    #   => 'foo=123&bar=456'
    #
    # @example Simple arrays
    #   >> encode_query_string({foo: [1,2,3]})
    #   => 'foo[]=1&foo[]=2&foo[]=3'
    #
    # @example Nested hashes
    #   >> encode_query_string({outer: {foo: 123, bar: 456}})
    #   => 'outer[foo]=123&outer[bar]=456'
    #
    # @example Deeply nesting
    #   >> encode_query_string({coords: [{x: 1, y: 0}, {x: 2}, {x: 3}]})
    #   => 'coords[][x]=1&coords[][y]=0&coords[][x]=2&coords[][x]=3'
    #
    # @example Null and empty values
    #   >> encode_query_string({string: '', empty: nil, list: [], hash: {}})
    #   => 'string=&empty&list&hash'
    #
    # @example Nested nulls
    #   >> encode_query_string({foo: {string: '', empty: nil}})
    #   => 'foo[string]=&foo[empty]'
    #
    # @example Multiple fields with the same name using ParamsArray
    #   >> encode_query_string(RestClient::ParamsArray.new([[:foo, 1], [:foo, 2], [:foo, 3]]))
    #   => 'foo=1&foo=2&foo=3'
    #
    # @example Nested ParamsArray
    #   >> encode_query_string({foo: RestClient::ParamsArray.new([[:a, 1], [:a, 2]])})
    #   => 'foo[a]=1&foo[a]=2'
    #
    #   >> encode_query_string(RestClient::ParamsArray.new([[:foo, {a: 1}], [:foo, {a: 2}]]))
    #   => 'foo[a]=1&foo[a]=2'
    #
    def self.encode_query_string(object)
      flatten_params(object, true).map {|k, v| v.nil? ? k : "#{k}=#{v}" }.join('&')
    end

    # Transform deeply nested param containers into a flat array of [key,
    # value] pairs.
    #
    # @example
    #   >> flatten_params({key1: {key2: 123}})
    #   => [["key1[key2]", 123]]
    #
    # @example
    #   >> flatten_params({key1: {key2: 123, arr: [1,2,3]}})
    #   => [["key1[key2]", 123], ["key1[arr][]", 1], ["key1[arr][]", 2], ["key1[arr][]", 3]]
    #
    # @param object [Hash, ParamsArray] The container to flatten
    # @param uri_escape [Boolean] Whether to URI escape keys and values
    # @param parent_key [String] Should not be passed (used for recursion)
    #
    def self.flatten_params(object, uri_escape=false, parent_key=nil)
      unless object.is_a?(Hash) || object.is_a?(ParamsArray) ||
             (parent_key && object.is_a?(Array))
        raise ArgumentError.new('expected Hash or ParamsArray, got: ' + object.inspect)
      end

      # transform empty collections into nil, where possible
      if object.empty? && parent_key
        return [[parent_key, nil]]
      end

      # This is essentially .map(), but we need to do += for nested containers
      object.reduce([]) { |result, item|
        if object.is_a?(Array)
          # item is already the value
          k = nil
          v = item
        else
          # item is a key, value pair
          k, v = item
          k = escape(k.to_s) if uri_escape
        end

        processed_key = parent_key ? "#{parent_key}[#{k}]" : k

        case v
        when Array, Hash, ParamsArray
          result.concat flatten_params(v, uri_escape, processed_key)
        else
          v = escape(v.to_s) if uri_escape && v
          result << [processed_key, v]
        end
      }
    end

    # Encode string for safe transport by URI or form encoding. This uses a CGI
    # style escape, which transforms ` ` into `+` and various special
    # characters into percent encoded forms.
    #
    # This calls URI.encode_www_form_component for the implementation. The only
    # difference between this and CGI.escape is that it does not escape `*`.
    # http://stackoverflow.com/questions/25085992/
    #
    # @see URI.encode_www_form_component
    #
    def self.escape(string)
      URI.encode_www_form_component(string)
    end
  end
end
