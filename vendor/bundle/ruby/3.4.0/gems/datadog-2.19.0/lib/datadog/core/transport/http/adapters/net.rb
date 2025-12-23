# frozen_string_literal: true

require_relative '../../../../core/transport/response'
require_relative '../../../../core/vendor/multipart-post/net/http/post/multipart'

module Datadog
  module Core
    module Transport
      module HTTP
        module Adapters
          # Adapter for Net::HTTP
          class Net
            attr_reader \
              :hostname,
              :port,
              :timeout,
              :ssl

            def initialize(agent_settings)
              @hostname = agent_settings.hostname
              @port = agent_settings.port
              @timeout = agent_settings.timeout_seconds
              @ssl = agent_settings.ssl
            end

            def self.build(agent_settings)
              new(agent_settings)
            end

            def open(&block)
              # DEV Initializing +Net::HTTP+ directly help us avoid expensive
              # options processing done in +Net::HTTP.start+:
              # https://github.com/ruby/ruby/blob/b2d96abb42abbe2e01f010ffc9ac51f0f9a50002/lib/net/http.rb#L614-L618
              req = ::Net::HTTP.new(hostname, port, nil)

              req.use_ssl = ssl
              req.open_timeout = req.read_timeout = timeout

              req.start(&block)
            end

            def call(env)
              if respond_to?(env.verb)
                send(env.verb, env)
              else
                raise UnknownHTTPMethod, env
              end
            end

            def get(env)
              get = ::Net::HTTP::Get.new(net_http_path_from_env(env), env.headers)

              # Connect and send the request
              http_response = open do |http|
                http.request(get)
              end

              # Build and return response
              Response.new(http_response)
            end

            def post(env)
              post = nil

              if env.form.nil? || env.form.empty?
                post = ::Net::HTTP::Post.new(net_http_path_from_env(env), env.headers)
                post.body = env.body
              else
                post = ::Datadog::Core::Vendor::Net::HTTP::Post::Multipart.new(
                  env.path,
                  env.form,
                  env.headers
                )
              end

              # Connect and send the request
              http_response = open do |http|
                http.request(post)
              end

              # Build and return response
              Response.new(http_response)
            end

            def url
              "http://#{hostname}:#{port}?timeout=#{timeout}"
            end

            def net_http_path_from_env(env)
              path = env.path
              case query = env.query
              when Hash
                path = path + '?' + URI.encode_www_form(query)
              when String
                path = path + '?' + query
              when nil
                # Nothing
              else
                raise ArgumentError, "Invalid type for query: #{query}"
              end
              path
            end

            # Raised when called with an unknown HTTP method
            class UnknownHTTPMethod < StandardError
              attr_reader :verb

              def initialize(verb)
                super("No matching Net::HTTP function for '#{verb}'!")
              end
            end

            # A wrapped Net::HTTP response that implements the Transport::Response interface
            class Response
              include Datadog::Core::Transport::Response

              attr_reader :http_response

              def initialize(http_response)
                @http_response = http_response
              end

              def payload
                return super if http_response.nil?

                http_response.body
              end

              def code
                return super if http_response.nil?

                http_response.code.to_i
              end

              def ok?
                return super if http_response.nil?

                code.between?(200, 299)
              end

              def unsupported?
                return super if http_response.nil?

                code == 415
              end

              def not_found?
                return super if http_response.nil?

                code == 404
              end

              def client_error?
                return super if http_response.nil?

                code.between?(400, 499)
              end

              def server_error?
                return super if http_response.nil?

                code.between?(500, 599)
              end

              def inspect
                "#{super}, http_response:#{http_response}"
              end
            end
          end
        end
      end
    end
  end
end
