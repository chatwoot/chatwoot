# frozen_string_literal: true

begin
  require 'async'
  require 'async/http'
rescue LoadError
  # async-http not found
end

if defined?(Async::HTTP)
  module WebMock
    module HttpLibAdapters
      class AsyncHttpClientAdapter < HttpLibAdapter
        adapter_for :async_http_client

        OriginalAsyncHttpClient = Async::HTTP::Client unless const_defined?(:OriginalAsyncHttpClient)

        class << self
          def enable!
            Async::HTTP.send(:remove_const, :Client)
            Async::HTTP.send(:const_set, :Client, Async::HTTP::WebMockClientWrapper)
          end

          def disable!
            Async::HTTP.send(:remove_const, :Client)
            Async::HTTP.send(:const_set, :Client, OriginalAsyncHttpClient)
          end
        end
      end
    end
  end

  module Async
    module HTTP
      class WebMockClientWrapper < Client
        def initialize(
          endpoint,
          protocol = endpoint.protocol,
          scheme = endpoint.scheme,
          authority = endpoint.authority,
          **options
        )
          webmock_endpoint = WebMockEndpoint.new(scheme, authority, protocol)

          @network_client = WebMockClient.new(endpoint, **options)
          @webmock_client = WebMockClient.new(webmock_endpoint, **options)

          @scheme = scheme
          @authority = authority
        end

        def call(request)
          request.scheme ||= self.scheme
          request.authority ||= self.authority

          request_signature = build_request_signature(request)
          WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)
          webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
          net_connect_allowed = WebMock.net_connect_allowed?(request_signature.uri)
          real_request = false

          if webmock_response
            webmock_response.raise_error_if_any
            raise Async::TimeoutError, 'WebMock timeout error' if webmock_response.should_timeout
            WebMockApplication.add_webmock_response(request, webmock_response)
            response = @webmock_client.call(request)
          elsif net_connect_allowed
            response = @network_client.call(request)
            real_request = true
          else
            raise WebMock::NetConnectNotAllowedError.new(request_signature) unless webmock_response
          end

          if WebMock::CallbackRegistry.any_callbacks?
            webmock_response ||= build_webmock_response(response)
            WebMock::CallbackRegistry.invoke_callbacks(
              {
                lib: :async_http_client,
                real_request: real_request
              },
              request_signature,
              webmock_response
            )
          end

          response
        end

        def close
          @network_client.close
          @webmock_client.close
        end

        private

        def build_request_signature(request)
          body = request.read
          request.body = ::Protocol::HTTP::Body::Buffered.wrap(body)
          WebMock::RequestSignature.new(
            request.method.downcase.to_sym,
            "#{request.scheme}://#{request.authority}#{request.path}",
            headers: request.headers.to_h,
            body: body
          )
        end

        def build_webmock_response(response)
          body = response.read
          response.body = ::Protocol::HTTP::Body::Buffered.wrap(body)

          webmock_response = WebMock::Response.new
          webmock_response.status = [
            response.status,
            ::Protocol::HTTP1::Reason::DESCRIPTIONS[response.status]
          ]
          webmock_response.headers = build_webmock_response_headers(response)
          webmock_response.body = body
          webmock_response
        end

        def build_webmock_response_headers(response)
          response.headers.each.each_with_object({}) do |(k, v), o|
            o[k] ||= []
            o[k] << v
          end
        end
      end

      class WebMockClient < Client
      end

      class WebMockEndpoint
        def initialize(scheme, authority, protocol)
          @scheme = scheme
          @authority = authority
          @protocol = protocol
        end

        attr :scheme, :authority, :protocol

        def connect
          server_socket, client_socket = create_connected_sockets
          Async(transient: true) do
            accept_socket(server_socket)
          end
          client_socket
        end

        def inspect
          "\#<#{self.class}> #{scheme}://#{authority} protocol=#{protocol}"
        end

        private

        def socket_class
          defined?(Async::IO::Socket) ? Async::IO::Socket : Socket
        end

        def create_connected_sockets
          pair = begin
            socket_class.pair(Socket::AF_UNIX, Socket::SOCK_STREAM)
          rescue Errno::EAFNOSUPPORT
            socket_class.pair(Socket::AF_INET, Socket::SOCK_STREAM)
          end
          pair.tap do |sockets|
            sockets.each do |socket|
              socket.instance_variable_set :@alpn_protocol, nil
              socket.instance_eval do
                def alpn_protocol
                  nil # means HTTP11 will be used for HTTPS
                end
              end
            end
          end
        end

        def accept_socket(socket)
          server = Async::HTTP::Server.new(WebMockApplication, self)
          server.accept(socket, socket.remote_address)
        end
      end

      module WebMockApplication
        WEBMOCK_REQUEST_ID_HEADER = 'x-webmock-request-id'.freeze

        class << self
          def call(request)
            request.read
            webmock_response = get_webmock_response(request)
            build_response(webmock_response)
          end

          def add_webmock_response(request, webmock_response)
            webmock_request_id = request.object_id.to_s
            request.headers.add(WEBMOCK_REQUEST_ID_HEADER, webmock_request_id)
            webmock_responses[webmock_request_id] = webmock_response
          end

          def get_webmock_response(request)
            webmock_request_id = request.headers[WEBMOCK_REQUEST_ID_HEADER][0]
            webmock_responses.fetch(webmock_request_id)
          end

          private

          def webmock_responses
            @webmock_responses ||= {}
          end

          def build_response(webmock_response)
            headers = (webmock_response.headers || {}).each_with_object([]) do |(k, value), o|
              Array(value).each do |v|
                o.push [k, v]
              end
            end

            ::Protocol::HTTP::Response[
              webmock_response.status[0],
              headers,
              webmock_response.body
            ]
          end
        end
      end
    end
  end
end
