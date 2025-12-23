# frozen_string_literal: true

begin
  require 'net/https'
rescue LoadError
  warn 'Warning: no such file to load -- net/https. ' \
    'Make sure openssl is installed if you want ssl support'
  require 'net/http'
end
require 'zlib'

module Faraday
  class Adapter
    class NetHttp < Faraday::Adapter
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
      exceptions << ::Net::OpenTimeout if defined?(::Net::OpenTimeout)

      NET_HTTP_EXCEPTIONS = exceptions.freeze

      def initialize(app = nil, opts = {}, &block)
        @ssl_cert_store = nil
        super(app, opts, &block)
      end

      def build_connection(env)
        net_http_connection(env).tap do |http|
          configure_ssl(http, env[:ssl]) if env[:url].scheme == 'https' && env[:ssl]
          configure_request(http, env[:request])
        end
      end

      def net_http_connection(env)
        proxy = env[:request][:proxy]
        port = env[:url].port || (env[:url].scheme == 'https' ? 443 : 80)
        if proxy
          Net::HTTP.new(env[:url].hostname, port,
                        proxy[:uri].hostname, proxy[:uri].port,
                        proxy[:user], proxy[:password],
                        nil, proxy[:uri].scheme == 'https')
        else
          Net::HTTP.new(env[:url].hostname, port, nil)
        end
      end

      def call(env)
        super
        connection(env) do |http|
          perform_request(http, env)
        rescue *NET_HTTP_EXCEPTIONS => e
          raise Faraday::SSLError, e if defined?(OpenSSL) && e.is_a?(OpenSSL::SSL::SSLError)

          raise Faraday::ConnectionFailed, e
        end
        @app.call env
      rescue Timeout::Error, Errno::ETIMEDOUT => e
        raise Faraday::TimeoutError, e
      end

      private

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

      def request_with_wrapped_block(http, env, &block)
        # Must use Net::HTTP#start and pass it a block otherwise the server's
        # TCP socket does not close correctly.
        http.start do |opened_http|
          opened_http.request create_request(env) do |response|
            save_http_response(env, response)

            response.read_body(&block) if block_given?
          end
        end
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

      def configure_ssl(http, ssl)
        http.use_ssl = true if http.respond_to?(:use_ssl=)

        http.verify_mode = ssl_verify_mode(ssl)
        http.cert_store = ssl_cert_store(ssl)

        cert, *extra_chain_cert = ssl[:client_cert]
        http.cert = cert if cert
        http.extra_chain_cert = extra_chain_cert if extra_chain_cert.any?

        http.key = ssl[:client_key] if ssl[:client_key]
        http.ca_file = ssl[:ca_file] if ssl[:ca_file]
        http.ca_path = ssl[:ca_path] if ssl[:ca_path]
        http.verify_depth = ssl[:verify_depth] if ssl[:verify_depth]
        http.ssl_version = ssl[:version] if ssl[:version]
        http.min_version = ssl[:min_version] if ssl[:min_version]
        http.max_version = ssl[:max_version] if ssl[:max_version]
        http.verify_hostname = ssl[:verify_hostname] if verify_hostname_enabled?(http, ssl)
        http.ciphers = ssl[:ciphers] if ssl[:ciphers]
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

      def ssl_verify_mode(ssl)
        ssl[:verify_mode] || begin
          if ssl.fetch(:verify, true)
            OpenSSL::SSL::VERIFY_PEER
          else
            OpenSSL::SSL::VERIFY_NONE
          end
        end
      end

      def encoded_body(http_response)
        body = http_response.body || +''
        /\bcharset=([^;]+)/.match(http_response['Content-Type']) do |match|
          content_charset = ::Encoding.find(match[1].strip)
          body = body.dup if body.frozen?
          body.force_encoding(content_charset)
        rescue ArgumentError
          nil
        end
        body
      end

      def verify_hostname_enabled?(http, ssl)
        http.respond_to?(:verify_hostname=) && ssl.key?(:verify_hostname)
      end
    end
  end
end
