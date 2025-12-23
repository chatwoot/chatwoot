# frozen_string_literal: true

require "net/http/persistent"

module Faraday
  class Adapter
    # Net::HTTP::Persistent adapter.
    class NetHttpPersistent < Faraday::Adapter
      exceptions = [
        IOError,
        Errno::EADDRNOTAVAIL,
        Errno::EALREADY,
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EINVAL,
        Errno::ENETUNREACH,
        Errno::EPIPE,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        SocketError,
        Zlib::GzipFile::Error
      ]

      exceptions << ::OpenSSL::SSL::SSLError if defined?(::OpenSSL::SSL::SSLError)
      # TODO (breaking): Enable this to make it consistent with net_http adapter.
      #   See https://github.com/lostisland/faraday/issues/718#issuecomment-344549382
      # exceptions << ::Net::OpenTimeout if defined?(::Net::OpenTimeout)

      NET_HTTP_EXCEPTIONS = exceptions.freeze

      def initialize(app = nil, opts = {}, &block)
        @ssl_cert_store = nil
        super(app, opts, &block)
      end

      def call(env)
        super
        connection(env) do |http|
          perform_request(http, env)
        rescue Net::HTTP::Persistent::Error => e
          raise Faraday::TimeoutError, e if e.message.include?("Timeout")

          raise Faraday::ConnectionFailed, e if e.message.include?("connection refused")

          raise
        rescue *NET_HTTP_EXCEPTIONS => e
          raise Faraday::SSLError, e if defined?(OpenSSL) && e.is_a?(OpenSSL::SSL::SSLError)

          raise Faraday::ConnectionFailed, e
        end
        @app.call env
      rescue Timeout::Error, Errno::ETIMEDOUT => e
        raise Faraday::TimeoutError, e
      end

      private

      def build_connection(env)
        net_http_connection(env).tap do |http|
          http.use_ssl = env[:url].scheme == "https" if http.respond_to?(:use_ssl=)
          configure_ssl(http, env[:ssl])
          configure_request(http, env[:request])
        end
      end

      def create_request(env)
        request = Net::HTTPGenericRequest.new \
          env[:method].to_s.upcase, # request method
          !!env[:body], # is there request body
          env[:method] != :head, # is there response body
          env[:url].request_uri, # request uri path
          env[:request_headers] # request headers

        if env[:body].respond_to?(:read)
          request.body_stream = env[:body]
        else
          request.body = env[:body]
        end
        request
      end

      def save_http_response(env, http_response)
        save_response(
          env, http_response.code.to_i, nil, nil, http_response.message, finished: false
        ) do |response_headers|
          http_response.each_header do |key, value|
            response_headers[key] = value
          end
        end
      end

      def configure_request(http, req)
        if (sec = request_timeout(:read, req))
          http.read_timeout = sec
        end

        if (sec = http.respond_to?(:write_timeout=) &&
          request_timeout(:write, req))
          http.write_timeout = sec
        end

        if (sec = request_timeout(:open, req))
          http.open_timeout = sec
        end

        # Only set if Net::Http supports it, since Ruby 2.5.
        http.max_retries = 0 if http.respond_to?(:max_retries=)

        @config_block&.call(http)
      end

      def ssl_cert_store(ssl)
        return ssl[:cert_store] if ssl[:cert_store]

        # Use the default cert store by default, i.e. system ca certs
        @ssl_cert_store ||= OpenSSL::X509::Store.new.tap(&:set_default_paths)
      end

      def net_http_connection(env)
        @cached_connection ||= Net::HTTP::Persistent.new(**init_options)

        proxy_uri = proxy_uri(env)
        @cached_connection.proxy = proxy_uri if @cached_connection.proxy_uri != proxy_uri
        @cached_connection
      end

      def init_options
        options = {name: "Faraday"}
        options[:pool_size] = @connection_options[:pool_size] if @connection_options.key?(:pool_size)
        options
      end

      def proxy_uri(env)
        proxy_uri = nil
        if (proxy = env[:request][:proxy])
          proxy_uri = if proxy[:uri].is_a?(::URI::HTTP)
            proxy[:uri].dup
          else
            ::URI.parse(proxy[:uri].to_s)
          end
          proxy_uri.user = proxy[:user] if proxy[:user]
          proxy_uri.password = proxy[:password] if proxy[:password]
        end
        proxy_uri
      end

      def perform_request(http, env)
        if env.stream_response?
          http_response = env.stream_response do |&on_data|
            request_with_wrapped_block(http, env, &on_data)
          end
          http_response.body = nil
        else
          http_response = request_with_wrapped_block(http, env)
        end
        env.response_body = encoded_body(http_response)
        env.response.finish(env)
        http_response
      end

      def request_with_wrapped_block(http, env)
        http.request(env[:url], create_request(env)) do |response|
          save_http_response(env, response)

          if block_given?
            response.read_body do |chunk|
              yield(chunk)
            end
          end
        end
      end

      SSL_CONFIGURATIONS = {
        certificate: :client_cert,
        private_key: :client_key,
        ca_file: :ca_file,
        ssl_version: :version,
        min_version: :min_version,
        max_version: :max_version
      }.freeze

      def configure_ssl(http, ssl)
        return unless ssl

        http_set(http, :verify_mode, ssl_verify_mode(ssl))
        http_set(http, :cert_store, ssl_cert_store(ssl))

        SSL_CONFIGURATIONS
          .select { |_, key| ssl[key] }
          .each { |target, key| http_set(http, target, ssl[key]) }
      end

      def http_set(http, attr, value)
        http.send("#{attr}=", value) if http.send(attr) != value
      end

      def ssl_verify_mode(ssl)
        ssl[:verify_mode] ||
          if ssl.fetch(:verify, true)
            OpenSSL::SSL::VERIFY_PEER
          else
            OpenSSL::SSL::VERIFY_NONE
          end
      end

      def encoded_body(http_response)
        body = http_response.body || +""
        /\bcharset=\s*(.+?)\s*(;|$)/.match(http_response["Content-Type"]) do |match|
          content_charset = ::Encoding.find(match.captures.first)
          body = body.dup if body.frozen?
          body.force_encoding(content_charset)
        rescue ArgumentError
          nil
        end
        body
      end
    end
  end
end
