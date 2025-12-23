# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      class Expect100Continue < Seahorse::Client::Plugin

        def add_handlers(handlers, config)
          if config.http_continue_timeout && config.http_continue_timeout > 0
            handlers.add(Handler)
          end
        end

        # @api private
        class Handler < Seahorse::Client::Handler

          def call(context)
            body = context.http_request.body
            if body.respond_to?(:size) && body.size > 0 &&
               !context[:use_accelerate_endpoint]
              context.http_request.headers['expect'] = '100-continue'
            end
            @handler.call(context)
          end

        end
      end
    end
  end
end
