# frozen_string_literal: true

module Aws
  module Plugins

    # For Streaming Input Operations, when `requiresLength` is enabled
    # checking whether `Content-Length` header can be set,
    # for `v4-unsigned-body` operations, set `Transfer-Encoding` header
    class TransferEncoding < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          if streaming?(context.operation.input)
            # If it's an IO object and not a File / String / String IO
            unless context.http_request.body.respond_to?(:size)
              if requires_length?(context.operation.input)
                # if size of the IO is not available but required
                raise Aws::Errors::MissingContentLength.new
              elsif context.operation['authtype'] == "v4-unsigned-body"
                context.http_request.headers['Transfer-Encoding'] = 'chunked'
              end
            end
          end

          @handler.call(context)
        end

        private

        def streaming?(ref)
          if payload = ref[:payload_member]
            payload["streaming"] || # checking ref and shape
              payload.shape["streaming"]
          else
            false
          end
        end

        def requires_length?(ref)
          payload = ref[:payload_member]
          payload["requiresLength"] || # checking ref and shape
            payload.shape["requiresLength"]
        end

      end

      handler(Handler, step: :sign)

    end

  end
end
