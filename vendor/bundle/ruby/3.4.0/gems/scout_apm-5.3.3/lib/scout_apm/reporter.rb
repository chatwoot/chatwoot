require 'openssl'

module ScoutApm
  class Reporter
    VERIFY_MODE = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT

    attr_reader :type
    attr_reader :context
    attr_reader :instant_key

    def initialize(context, type, instant_key=nil)
      @context = context
      @type = type
      @instant_key = instant_key
    end

    def config
      context.config
    end

    def logger
      context.logger
    end

    # The fully serialized string payload to be sent
    def report(payload, headers = {})
      hosts = determine_hosts

      if config.value('compress_payload')
        original_payload_size = payload.length

        payload, compression_headers = compress_payload(payload)
        headers.merge!(compression_headers)

        compress_payload_size = payload.length
        logger.debug("Original Size: #{original_payload_size} Compressed Size: #{compress_payload_size}")
      end

      logger.info("Posting payload to #{hosts.inspect}")
      post_payload(hosts, payload, headers)
    end

    def uri(host)
      encoded_app_name = CGI.escape(context.environment.application_name)
      key = config.value('key')

      case type
      when :checkin
        URI.parse("#{host}/apps/checkin.scout?key=#{key}&name=#{encoded_app_name}")
      when :app_server_load
        URI.parse("#{host}/apps/app_server_load.scout?key=#{key}&name=#{encoded_app_name}")
      when :deploy_hook
        URI.parse("#{host}/apps/deploy.scout?key=#{key}&name=#{encoded_app_name}")
      when :instant_trace
        URI.parse("#{host}/apps/instant_trace.scout?key=#{key}&name=#{encoded_app_name}&instant_key=#{instant_key}")
      when :errors
        URI.parse("#{host}/apps/error.scout?key=#{key}&name=#{encoded_app_name}")
      end.tap { |u| logger.debug("Posting to #{u}") }
    end

    def can_report?
      case type
      when :deploy_hook
        %w(host key name).each do |k|
          if config.value(k).nil?
            logger.warn "/#{type} FAILED: missing required config value for #{k}"
            return false
          end
        end
        return true
      else
        return true
      end
    end

    private

    def post(uri, body, headers = Hash.new)
      response = :connection_failed
      request(uri) do |connection|
        post = Net::HTTP::Post.new( uri.path +
                                    (uri.query ? ('?' + uri.query) : ''),
                                    default_http_headers.merge(headers) )
        post.body = body
        response = connection.request(post)
      end
      response
    end

    def request(uri, &connector)
      response           = nil
      response           = http(uri).start(&connector)
      logger.debug "got response: #{response.inspect}"
      case response
      when Net::HTTPSuccess, Net::HTTPNotModified
        logger.debug "#{type} OK"
      when Net::HTTPBadRequest
        logger.warn "/#{type} FAILED: The Account Key [#{config.value('key')}] is invalid."
      when Net::HTTPUnprocessableEntity
        logger.warn "/#{type} FAILED: #{response.body}"
      else
        logger.debug "/#{type} FAILED: #{response.inspect}"
      end
    rescue Exception
      logger.info "Exception sending request to server: \n#{$!.message}\n\t#{$!.backtrace.join("\n\t")}"
    ensure
      response
    end

    # Headers passed up with all API requests.
    def default_http_headers
      { "Agent-Hostname" => context.environment.hostname,
        "Content-Type"   => "application/octet-stream",
        "Agent-Version"  => ScoutApm::VERSION,
      }
    end

    # Take care of the http proxy, if specified in config.
    # Given a blank string, the proxy_uri URI instance's host/port/user/pass will be nil.
    # Net::HTTP::Proxy returns a regular Net::HTTP class if the first argument (host) is nil.
    def http(url)
      proxy_uri = URI.parse(config.value('proxy').to_s)
      http = Net::HTTP::Proxy(proxy_uri.host,
                              proxy_uri.port,
                              proxy_uri.user,
                              proxy_uri.password).new(url.host, url.port)
      if url.is_a?(URI::HTTPS)
        http.use_ssl = true
        http.ca_file = config.value("ssl_cert_file")
        http.verify_mode = VERIFY_MODE
      end
      http
    end

    def compress_payload(payload)
      [
        ScoutApm::Utils::GzipHelper.new.deflate(payload),
        { 'Content-Encoding' => 'gzip' }
      ]
    end

    # Some posts (typically ones under development) bypass the ingestion
    # pipeline and go directly to the webserver. They use direct_host instead
    # of host
    def determine_hosts
      if [:deploy_hook, :instant_trace].include?(type)
        config.value('direct_host')
      elsif [:errors].include?(type)
        config.value('errors_host')
      else
        config.value('host')
      end
    end

    def post_payload(hosts, payload, headers)
      Array(hosts).each do |host|
        full_uri = uri(host)
        response = post(full_uri, payload, headers)
        unless response && response.is_a?(Net::HTTPSuccess)
          logger.warn "Error on checkin to #{full_uri}: #{response.inspect}"
        end
      end
    end
  end
end
