# frozen_string_literal: true

begin
  require 'typhoeus'
rescue LoadError
  # typhoeus not found
end

if defined?(Typhoeus)
  WebMock::VersionChecker.new('Typhoeus', Typhoeus::VERSION, '0.3.2').check_version!

  module WebMock
    module HttpLibAdapters
      class TyphoeusAdapter < HttpLibAdapter
        adapter_for :typhoeus

        def self.enable!
          @disabled = false
          add_before_callback
          add_after_request_callback
          ::Typhoeus::Config.block_connection = true
        end

        def self.disable!
          @disabled = true
          remove_after_request_callback
          remove_before_callback
          ::Typhoeus::Config.block_connection = false
        end

        def self.disabled?
          !!@disabled
        end

        def self.add_before_callback
          unless Typhoeus.before.include?(BEFORE_CALLBACK)
            Typhoeus.before << BEFORE_CALLBACK
          end
        end

        def self.remove_before_callback
          Typhoeus.before.delete_if {|v| v == BEFORE_CALLBACK }
        end

        def self.add_after_request_callback
          unless Typhoeus.on_complete.include?(AFTER_REQUEST_CALLBACK)
            Typhoeus.on_complete << AFTER_REQUEST_CALLBACK
          end
        end

        def self.remove_after_request_callback
          Typhoeus.on_complete.delete_if {|v| v == AFTER_REQUEST_CALLBACK }
        end

        def self.build_request_signature(req)
          uri = WebMock::Util::URI.heuristic_parse(req.url)
          uri.path = uri.normalized_path.gsub("[^:]//","/")

          headers = req.options[:headers]

          if req.options[:userpwd]
            headers['Authorization'] = WebMock::Util::Headers.basic_auth_header(req.options[:userpwd])
          end

          body = req.options[:body]

          if body.is_a?(Hash)
            body = WebMock::Util::QueryMapper.values_to_query(body)
          end

          request_signature = WebMock::RequestSignature.new(
            req.options[:method] || :get,
            uri.to_s,
            body: body,
            headers: headers
          )

          req.instance_variable_set(:@__webmock_request_signature, request_signature)

          request_signature
        end


        def self.build_webmock_response(typhoeus_response)
          webmock_response = WebMock::Response.new
          webmock_response.status = [typhoeus_response.code, typhoeus_response.status_message]
          webmock_response.body = typhoeus_response.body
          webmock_response.headers = typhoeus_response.headers
          webmock_response
        end

        def self.generate_typhoeus_response(request_signature, webmock_response)
          response = if webmock_response.should_timeout
            ::Typhoeus::Response.new(
              code: 0,
              status_message: "",
              body: "",
              headers: {},
              return_code: :operation_timedout,
              total_time: 0.0,
              starttransfer_time: 0.0,
              appconnect_time: 0.0,
              pretransfer_time: 0.0,
              connect_time: 0.0,
              namelookup_time: 0.0,
              redirect_time: 0.0
            )
          else
            ::Typhoeus::Response.new(
              code: webmock_response.status[0],
              status_message: webmock_response.status[1],
              body: webmock_response.body,
              headers: webmock_response.headers,
              effective_url: request_signature.uri,
              total_time: 0.0,
              starttransfer_time: 0.0,
              appconnect_time: 0.0,
              pretransfer_time: 0.0,
              connect_time: 0.0,
              namelookup_time: 0.0,
              redirect_time: 0.0
            )
          end
          response.mock = :webmock
          response
        end

        def self.request_hash(request_signature)
          hash = {}

          hash[:body]    = request_signature.body
          hash[:headers] = request_signature.headers

          hash
        end

        AFTER_REQUEST_CALLBACK = Proc.new do |response|
          request = response.request
          request_signature = request.instance_variable_get(:@__webmock_request_signature)
          webmock_response =
            ::WebMock::HttpLibAdapters::TyphoeusAdapter.
              build_webmock_response(response)
          if response.mock
            WebMock::CallbackRegistry.invoke_callbacks(
              {lib: :typhoeus},
              request_signature,
              webmock_response
            )
          else
            WebMock::CallbackRegistry.invoke_callbacks(
              {lib: :typhoeus, real_request: true},
              request_signature,
              webmock_response
            )
          end
        end

        BEFORE_CALLBACK = Proc.new do |request|
          Typhoeus::Expectation.all.delete_if {|e| e.from == :webmock }
          res = true

          unless WebMock::HttpLibAdapters::TyphoeusAdapter.disabled?
            request_signature = ::WebMock::HttpLibAdapters::TyphoeusAdapter.build_request_signature(request)
            request.block_connection = false;

            ::WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

            if webmock_response = ::WebMock::StubRegistry.instance.response_for_request(request_signature)
              # ::WebMock::HttpLibAdapters::TyphoeusAdapter.stub_typhoeus(request_signature, webmock_response, self)
              response = ::WebMock::HttpLibAdapters::TyphoeusAdapter.generate_typhoeus_response(request_signature, webmock_response)
              if request.respond_to?(:on_headers)
                request.execute_headers_callbacks(response)
              end
              if request.respond_to?(:streaming?) && request.streaming?
                response.options[:response_body] = ""
                request.on_body.each { |callback| callback.call(webmock_response.body, response) }
              end
              request.finish(response)
              webmock_response.raise_error_if_any
              res = false
            elsif !WebMock.net_connect_allowed?(request_signature.uri)
              raise WebMock::NetConnectNotAllowedError.new(request_signature)
            end
          end
          res
        end
      end
    end
  end
end
