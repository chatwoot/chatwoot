# frozen_string_literal: true

begin
  require 'excon'
rescue LoadError
  # excon not found
end

if defined?(Excon)
  WebMock::VersionChecker.new('Excon', Excon::VERSION, '0.27.5').check_version!

  module WebMock
    module HttpLibAdapters

      class ExconAdapter < HttpLibAdapter
        PARAMS_TO_DELETE = [:expects, :idempotent,
                            :instrumentor_name, :instrumentor,
                            :response_block,
                            :__construction_args, :stack,
                            :connection, :response]

        adapter_for :excon

        instance_exec do
          @original_excon_mock_default = nil
          @stub = nil
        end

        def self.enable!
          self.add_excon_stub
        end

        def self.disable!
          self.remove_excon_stub
        end

        def self.add_excon_stub
          if not @stub
            @original_excon_mock_default = ::Excon.defaults[:mock]
            ::Excon.defaults[:mock] = true
            @stub = ::Excon.stub({}) do |params|
              self.handle_request(params)
            end
          end
        end

        def self.remove_excon_stub
          ::Excon.defaults[:mock] = @original_excon_mock_default
          @original_excon_mock_default = nil
          Excon.stubs.delete(@stub)
          @stub = nil
        end

        def self.handle_request(params)
          mock_request  = self.build_request params.dup
          WebMock::RequestRegistry.instance.requested_signatures.put(mock_request)

          if mock_response = WebMock::StubRegistry.instance.response_for_request(mock_request)
            self.perform_callbacks(mock_request, mock_response, real_request: false)
            response = self.real_response(mock_response)
            response
          elsif WebMock.net_connect_allowed?(mock_request.uri)
            conn = new_excon_connection(params)
            real_response = conn.request(request_params_from(params.merge(mock: false)))

            ExconAdapter.perform_callbacks(mock_request, ExconAdapter.mock_response(real_response), real_request: true)

            real_response.data
          else
            raise WebMock::NetConnectNotAllowedError.new(mock_request)
          end
        end

        def self.new_excon_connection(params)
          # Ensure the connection is constructed with the exact same args
          # that the orginal connection was constructed with.
          args = params.fetch(:__construction_args)
          ::Excon::Connection.new(connection_params_from args.merge(mock: false))
        end

        def self.connection_params_from(hash)
          hash = hash.dup
          PARAMS_TO_DELETE.each { |key| hash.delete(key) }
          hash
        end

        def self.request_params_from(hash)
          hash = hash.dup
          if defined?(Excon::VALID_REQUEST_KEYS)
            hash.reject! {|key,_| !Excon::VALID_REQUEST_KEYS.include?(key) }
          end
          PARAMS_TO_DELETE.each { |key| hash.delete(key) }
          hash
        end

        def self.to_query(hash)
          string = "".dup
          for key, values in hash
            if values.nil?
              string << key.to_s << '&'
            else
              for value in [*values]
                string << key.to_s << '=' << CGI.escape(value.to_s) << '&'
              end
            end
          end
          string.chop! # remove trailing '&'
        end

        def self.build_request(params)
          params = params.dup
          params.delete(:user)
          params.delete(:password)
          method  = (params.delete(:method) || :get).to_s.downcase.to_sym
          params[:query] = to_query(params[:query]) if params[:query].is_a?(Hash)
          uri = Addressable::URI.new(params).to_s
          WebMock::RequestSignature.new method, uri, body: body_from(params), headers: params[:headers]
        end

        def self.body_from(params)
          body = params[:body]
          return body unless body.respond_to?(:read)

          contents = body.read
          body.rewind if body.respond_to?(:rewind)
          contents
        end

        def self.real_response(mock)
          raise Excon::Errors::Timeout if mock.should_timeout
          mock.raise_error_if_any
          {
            body: mock.body,
            status: mock.status[0].to_i,
            reason_phrase: mock.status[1],
            headers: mock.headers || {}
          }
        end

        def self.mock_response(real)
          mock = WebMock::Response.new
          mock.status  = [real.status, real.reason_phrase]
          mock.headers = real.headers
          mock.body    = real.body.dup
          mock
        end

        def self.perform_callbacks(request, response, options = {})
          return unless WebMock::CallbackRegistry.any_callbacks?
          WebMock::CallbackRegistry.invoke_callbacks(options.merge(lib: :excon), request, response)
        end
      end
    end
  end

  Excon::Connection.class_eval do
    def self.new(args = {})
      args.delete(:__construction_args)
      super(args).tap do |instance|
        instance.data[:__construction_args] = args
      end
    end
  end

  # Suppresses Excon connection argument validation warning
  Excon::VALID_CONNECTION_KEYS << :__construction_args
end
