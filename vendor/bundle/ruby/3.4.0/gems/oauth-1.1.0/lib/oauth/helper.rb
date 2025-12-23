# frozen_string_literal: true

require "time"
require "openssl"
require "base64"

module OAuth
  module Helper
    module_function

    # Escape +value+ by URL encoding all non-reserved character.
    #
    # See Also: {OAuth core spec version 1.0, section 5.1}[http://oauth.net/core/1.0#rfc.section.5.1]
    def escape(value)
      _escape(value.to_s.to_str)
    rescue ArgumentError
      _escape(value.to_s.to_str.force_encoding(Encoding::UTF_8))
    end

    def _escape(string)
      URI::DEFAULT_PARSER.escape(string, OAuth::RESERVED_CHARACTERS)
    end

    def unescape(value)
      URI::DEFAULT_PARSER.unescape(value.gsub("+", "%2B"))
    end

    # Generate a random key of up to +size+ bytes. The value returned is Base64 encoded with non-word
    # characters removed.
    def generate_key(size = 32)
      Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, "")
    end

    alias generate_nonce generate_key

    def generate_timestamp # :nodoc:
      Time.now.to_i.to_s
    end

    # Normalize a +Hash+ of parameter values. Parameters are sorted by name, using lexicographical
    # byte value ordering. If two or more parameters share the same name, they are sorted by their value.
    # Parameters are concatenated in their sorted order into a single string. For each parameter, the name
    # is separated from the corresponding value by an "=" character, even if the value is empty. Each
    # name-value pair is separated by an "&" character.
    #
    # See Also: {OAuth core spec version 1.0, section 9.1.1}[http://oauth.net/core/1.0#rfc.section.9.1.1]
    def normalize(params)
      params.sort.map do |k, values|
        case values
        when Array
          # make sure the array has an element so we don't lose the key
          values << nil if values.empty?
          # multiple values were provided for a single key
          if values[0].is_a?(Hash)
            normalize_nested_query(values, k)
          else
            values.sort.collect do |v|
              [escape(k), escape(v)].join("=")
            end
          end
        when Hash
          normalize_nested_query(values, k)
        else
          [escape(k), escape(values)].join("=")
        end
      end * "&"
    end

    # Returns a string representation of the Hash like in URL query string
    # build_nested_query({:level_1 => {:level_2 => ['value_1','value_2']}}, 'prefix'))
    #   #=> ["prefix%5Blevel_1%5D%5Blevel_2%5D%5B%5D=value_1", "prefix%5Blevel_1%5D%5Blevel_2%5D%5B%5D=value_2"]
    def normalize_nested_query(value, prefix = nil)
      case value
      when Array
        value.map do |v|
          normalize_nested_query(v, "#{prefix}[]")
        end.flatten.sort
      when Hash
        value.map do |k, v|
          normalize_nested_query(v, prefix ? "#{prefix}[#{k}]" : k)
        end.flatten.sort
      else
        [escape(prefix), escape(value)].join("=")
      end
    end

    # Parse an Authorization / WWW-Authenticate header into a hash. Takes care of unescaping and
    # removing surrounding quotes. Raises a OAuth::Problem if the header is not parsable into a
    # valid hash. Does not validate the keys or values.
    #
    #   hash = parse_header(headers['Authorization'] || headers['WWW-Authenticate'])
    #   hash['oauth_timestamp']
    #     #=>"1234567890"
    #
    def parse_header(header)
      # decompose
      params = header[6, header.length].split(/[,=&]/)

      # odd number of arguments - must be a malformed header.
      raise OAuth::Problem, "Invalid authorization header" if params.size.odd?

      params.map! do |v|
        # strip and unescape
        val = unescape(v.strip)
        # strip quotes
        val.sub(/^"(.*)"$/, '\1')
      end

      # convert into a Hash
      Hash[*params.flatten]
    end

    def stringify_keys(hash)
      new_h = {}
      hash.each do |k, v|
        new_h[k.to_s] = v.is_a?(Hash) ? stringify_keys(v) : v
      end
      new_h
    end
  end
end
