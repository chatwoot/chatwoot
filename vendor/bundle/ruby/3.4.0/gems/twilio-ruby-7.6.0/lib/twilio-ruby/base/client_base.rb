module Twilio
  module REST
    class ClientBase
      # rubocop:disable Style/ClassVars
      @@default_region = 'us1'
      # rubocop:enable Style/ClassVars

      attr_accessor :http_client, :username, :password, :account_sid, :auth_token, :region, :edge, :logger,
                    :user_agent_extensions, :credentials

      # rubocop:disable Metrics/ParameterLists
      def initialize(username = nil, password = nil, account_sid = nil, region = nil, http_client = nil, logger = nil,
                     user_agent_extensions = nil)
        @username = username || Twilio.account_sid
        @password = password || Twilio.auth_token
        @region = region || Twilio.region
        @edge = Twilio.edge
        @account_sid = account_sid || @username
        @auth_token = @password
        @auth = [@username, @password]
        @http_client = http_client || Twilio.http_client || Twilio::HTTP::Client.new
        @logger = logger || Twilio.logger
        @user_agent_extensions = user_agent_extensions || []
      end

      def credential_provider(credential_provider = nil)
        @credentials = credential_provider
        self
      end
      # rubocop:enable Metrics/ParameterLists

      ##
      # Makes a request to the Twilio API using the configured http client
      # Authentication information is automatically added if none is provided
      def request(host, port, method, uri, params = {}, data = {}, headers = {}, auth = nil, timeout = nil) # rubocop:disable Metrics/MethodLength
        auth ||= @auth
        headers = generate_headers(method, headers)
        uri = build_uri(uri)

        if @logger
          @logger.debug('--BEGIN Twilio API Request--')
          @logger.debug("Request Method: <#{method}>")

          headers.each do |key, value|
            @logger.debug("#{key}:#{value}") unless key.downcase == 'authorization'
          end

          url = URI(uri)
          @logger.debug("Host:#{url.host}")
          @logger.debug("Path:#{url.path}")
          @logger.debug("Query:#{url.query}")
          @logger.debug("Request Params:#{params}")
        end

        auth = @credentials.to_auth_strategy.auth_string unless @credentials.nil?

        response = @http_client.request(
          host,
          port,
          method,
          uri,
          params,
          data,
          headers,
          auth,
          timeout
        )

        if @logger
          @logger.debug("Response Status Code:#{response.status_code}")
          @logger.debug("Response Headers:#{response.headers}")
          @logger.debug('--END TWILIO API REQUEST--')
        end

        response
      end

      ##
      # Build the final request uri
      def build_uri(uri)
        return uri if @region.nil? && @edge.nil?

        parsed_url = URI(uri)
        pieces = parsed_url.host.split('.')
        product = pieces[0]
        domain = pieces[-2, 2]
        new_edge = @edge
        new_region = @region

        case pieces.length
        when 4
          new_region ||= pieces[1]
        when 5
          new_edge ||= pieces[1]
          new_region ||= pieces[2]
        end

        new_region = @@default_region if !new_edge.nil? && new_region.nil?

        parsed_url.host = [product, new_edge, new_region, domain].reject(&:nil?).join('.')
        parsed_url.to_s
      end

      ##
      # Validate the SSL certificates for the Twilio API
      def validate_ssl_certificate
        response = request('tls-test.twilio.com', '443', 'GET', 'https://tls-test.twilio.com')
        return unless response.status_code < 200 || response.status_code >= 300

        raise RestError.new 'Unexpected response from certificate endpoint', response
      end

      def generate_headers(method, headers)
        ruby_config = RbConfig::CONFIG
        headers['User-Agent'] =
          "twilio-ruby/#{Twilio::VERSION} (#{ruby_config['host_os']} #{ruby_config['host_cpu']}) Ruby/#{RUBY_VERSION}"
        headers['Accept-Charset'] = 'utf-8'

        user_agent_extensions.each { |extension| headers['User-Agent'] += " #{extension}" }

        if ['POST', 'PUT'].include?(method) && !headers['Content-Type']
          headers['Content-Type'] =
            'application/x-www-form-urlencoded'
        end

        headers['Accept'] = 'application/json' unless headers['Accept']
        headers
      end
    end
  end
end
