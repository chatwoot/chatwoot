# frozen_string_literal: true

require_relative '../../../../core/transport/response'

module Datadog
  module Core
    module Transport
      module HTTP
        module Adapters
          # Adapter for testing
          class Test
            attr_reader \
              :buffer,
              :status

            # @param buffer [Array] an optional array that will capture all spans sent to this adapter, defaults to +nil+
            # @deprecated Positional parameters are deprecated. Use named parameters instead.
            def initialize(buffer = nil, **options)
              @buffer = buffer || options[:buffer]
              @mutex = Mutex.new
              @status = 200
            end

            def call(env)
              add_request(env)
              Response.new(status)
            end

            def buffer?
              !@buffer.nil?
            end

            def add_request(env)
              @mutex.synchronize { buffer << env } if buffer?
            end

            def set_status!(status)
              @status = status
            end

            def url
            end

            # Response for test adapter
            class Response
              include Datadog::Core::Transport::Response

              attr_reader \
                :body,
                :code

              def initialize(code, body = nil)
                @code = code
                @body = body
              end

              def payload
                @body
              end

              def ok?
                code.between?(200, 299)
              end

              def unsupported?
                code == 415
              end

              def not_found?
                code == 404
              end

              def client_error?
                code.between?(400, 499)
              end

              def server_error?
                code.between?(500, 599)
              end

              def inspect
                "#{super}, code:#{code}"
              end
            end
          end
        end
      end
    end
  end
end
