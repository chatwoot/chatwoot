require 'net/http'
require 'net/https'
require 'uri'

unless defined?(ActiveSupport::JSON)
  begin
    require 'json'
  rescue LoadError
    raise LoadError, "Please install the 'json' or 'json_pure' gem to parse geocoder results."
  end
end

module Geocoder
  module Lookup

    class Base
      def initialize
        @cache = nil
      end

      ##
      # Human-readable name of the geocoding API.
      #
      def name
        fail
      end

      ##
      # Symbol which is used in configuration to refer to this Lookup.
      #
      def handle
        str = self.class.to_s
        str[str.rindex(':')+1..-1].gsub(/([a-z\d]+)([A-Z])/,'\1_\2').downcase.to_sym
      end

      ##
      # Query the geocoding API and return a Geocoder::Result object.
      # Returns +nil+ on timeout or error.
      #
      # Takes a search string (eg: "Mississippi Coast Coliseumf, Biloxi, MS",
      # "205.128.54.202") for geocoding, or coordinates (latitude, longitude)
      # for reverse geocoding. Returns an array of <tt>Geocoder::Result</tt>s.
      #
      def search(query, options = {})
        query = Geocoder::Query.new(query, options) unless query.is_a?(Geocoder::Query)
        results(query).map{ |r|
          result = result_class.new(r)
          result.cache_hit = @cache_hit if cache
          result
        }
      end

      ##
      # Return the URL for a map of the given coordinates.
      #
      # Not necessarily implemented by all subclasses as only some lookups
      # also provide maps.
      #
      def map_link_url(coordinates)
        nil
      end

      ##
      # Array containing string descriptions of keys required by the API.
      # Empty array if keys are optional or not required.
      #
      def required_api_key_parts
        []
      end

      ##
      # URL to use for querying the geocoding engine.
      #
      # Subclasses should not modify this method. Instead they should define
      # base_query_url and url_query_string. If absolutely necessary to
      # subclss this method, they must also subclass #cache_key.
      #
      def query_url(query)
        base_query_url(query) + url_query_string(query)
      end

      ##
      # The working Cache object.
      #
      def cache
        if @cache.nil? and store = configuration.cache
          cache_options = configuration.cache_options
          @cache = Cache.new(store, cache_options)
        end
        @cache
      end

      ##
      # Array containing the protocols supported by the api.
      # Should be set to [:http] if only HTTP is supported
      # or [:https] if only HTTPS is supported.
      #
      def supported_protocols
        [:http, :https]
      end

      private # -------------------------------------------------------------

      ##
      # String which, when concatenated with url_query_string(query)
      # produces the full query URL. Should include the "?" a the end.
      #
      def base_query_url(query)
        fail
      end

      ##
      # An object with configuration data for this particular lookup.
      #
      def configuration
        Geocoder.config_for_lookup(handle)
      end

      ##
      # Object used to make HTTP requests.
      #
      def http_client
        proxy_name = "#{protocol}_proxy"
        if proxy = configuration.send(proxy_name)
          proxy_url = !!(proxy =~ /^#{protocol}/) ? proxy : protocol + '://' + proxy
          begin
            uri = URI.parse(proxy_url)
          rescue URI::InvalidURIError
            raise ConfigurationError,
              "Error parsing #{protocol.upcase} proxy URL: '#{proxy_url}'"
          end
          Net::HTTP::Proxy(uri.host, uri.port, uri.user, uri.password)
        else
          Net::HTTP
        end
      end

      ##
      # Geocoder::Result object or nil on timeout or other error.
      #
      def results(query)
        fail
      end

      def query_url_params(query)
        query.options[:params] || {}
      end

      def url_query_string(query)
        hash_to_query(
          query_url_params(query).reject{ |key,value| value.nil? }
        )
      end

      ##
      # Key to use for caching a geocoding result. Usually this will be the
      # request URL, but in cases where OAuth is used and the nonce,
      # timestamp, etc varies from one request to another, we need to use
      # something else (like the URL before OAuth encoding).
      #
      def cache_key(query)
        base_query_url(query) + hash_to_query(cache_key_params(query))
      end

      def cache_key_params(query)
        # omit api_key and token because they may vary among requests
        query_url_params(query).reject do |key,value|
          key.to_s.match(/(key|token)/)
        end
      end

      ##
      # Class of the result objects
      #
      def result_class
        Geocoder::Result.const_get(self.class.to_s.split(":").last)
      end

      ##
      # Raise exception if configuration specifies it should be raised.
      # Return false if exception not raised.
      #
      def raise_error(error, message = nil)
        exceptions = configuration.always_raise
        if exceptions == :all or exceptions.include?( error.is_a?(Class) ? error : error.class )
          raise error, message
        else
          false
        end
      end

      ##
      # Returns a parsed search result (Ruby hash).
      #
      def fetch_data(query)
        parse_raw_data fetch_raw_data(query)
      rescue SocketError => err
        raise_error(err) or Geocoder.log(:warn, "Geocoding API connection cannot be established.")
      rescue Errno::ECONNREFUSED => err
        raise_error(err) or Geocoder.log(:warn, "Geocoding API connection refused.")
      rescue Geocoder::NetworkError => err
        raise_error(err) or Geocoder.log(:warn, "Geocoding API connection is either unreacheable or reset by the peer")
      rescue Timeout::Error => err
        raise_error(err) or Geocoder.log(:warn, "Geocoding API not responding fast enough " +
          "(use Geocoder.configure(:timeout => ...) to set limit).")
      end

      def parse_json(data)
        if defined?(ActiveSupport::JSON)
          ActiveSupport::JSON.decode(data)
        else
          JSON.parse(data)
        end
      rescue
        unless raise_error(ResponseParseError.new(data))
          Geocoder.log(:warn, "Geocoding API's response was not valid JSON")
          Geocoder.log(:debug, "Raw response: #{data}")
        end
      end

      ##
      # Parses a raw search result (returns hash or array).
      #
      def parse_raw_data(raw_data)
        parse_json(raw_data)
      end

      ##
      # Protocol to use for communication with geocoding services.
      # Set in configuration but not available for every service.
      #
      def protocol
        "http" + (use_ssl? ? "s" : "")
      end

      def valid_response?(response)
        (200..399).include?(response.code.to_i)
      end

      ##
      # Fetch a raw geocoding result (JSON string).
      # The result might or might not be cached.
      #
      def fetch_raw_data(query)
        key = cache_key(query)
        if cache and body = cache[key]
          @cache_hit = true
        else
          check_api_key_configuration!(query)
          response = make_api_request(query)
          check_response_for_errors!(response)
          body = response.body

          # apply the charset from the Content-Type header, if possible
          ct = response['content-type']

          if ct && ct['charset']
            charset = ct.split(';').select do |s|
              s['charset']
            end.first.to_s.split('=')
            if charset.length == 2
              body.force_encoding(charset.last) rescue ArgumentError
            end
          end

          if cache and valid_response?(response)
            cache[key] = body
          end
          @cache_hit = false
        end
        body
      end

      def check_response_for_errors!(response)
        if response.code.to_i == 400
          raise_error(Geocoder::InvalidRequest) ||
            Geocoder.log(:warn, "Geocoding API error: 400 Bad Request")
        elsif response.code.to_i == 401
          raise_error(Geocoder::RequestDenied) ||
            Geocoder.log(:warn, "Geocoding API error: 401 Unauthorized")
        elsif response.code.to_i == 402
          raise_error(Geocoder::OverQueryLimitError) ||
            Geocoder.log(:warn, "Geocoding API error: 402 Payment Required")
        elsif response.code.to_i == 429
          raise_error(Geocoder::OverQueryLimitError) ||
            Geocoder.log(:warn, "Geocoding API error: 429 Too Many Requests")
        elsif response.code.to_i == 503
          raise_error(Geocoder::ServiceUnavailable) ||
            Geocoder.log(:warn, "Geocoding API error: 503 Service Unavailable")
        end
      end

      ##
      # Make an HTTP(S) request to a geocoding API and
      # return the response object.
      #
      def make_api_request(query)
        uri = URI.parse(query_url(query))
        Geocoder.log(:debug, "Geocoder: HTTP request being made for #{uri.to_s}")
        http_client.start(uri.host, uri.port, use_ssl: use_ssl?, open_timeout: configuration.timeout, read_timeout: configuration.timeout) do |client|
          configure_ssl!(client) if use_ssl?
          req = Net::HTTP::Get.new(uri.request_uri, configuration.http_headers)
          if configuration.basic_auth[:user] and configuration.basic_auth[:password]
            req.basic_auth(
              configuration.basic_auth[:user],
              configuration.basic_auth[:password]
            )
          end
          client.request(req)
        end
      rescue Timeout::Error
        raise Geocoder::LookupTimeout
      rescue Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ENETUNREACH, Errno::ECONNRESET
        raise Geocoder::NetworkError
      end

      def use_ssl?
        if supported_protocols == [:https]
          true
        elsif supported_protocols == [:http]
          false
        else
          configuration.use_https
        end
      end

      def configure_ssl!(client); end

      def check_api_key_configuration!(query)
        key_parts = query.lookup.required_api_key_parts
        if key_parts.size > Array(configuration.api_key).size
          parts_string = key_parts.size == 1 ? key_parts.first : key_parts
          raise Geocoder::ConfigurationError,
            "The #{query.lookup.name} API requires a key to be configured: " +
            parts_string.inspect
        end
      end

      ##
      # Simulate ActiveSupport's Object#to_query.
      # Removes any keys with nil value.
      #
      def hash_to_query(hash)
        require 'cgi' unless defined?(CGI) && defined?(CGI.escape)
        hash.collect{ |p|
          p[1].nil? ? nil : p.map{ |i| CGI.escape i.to_s } * '='
        }.compact.sort * '&'
      end
    end
  end
end
