# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class RestJson < Seahorse::Client::Plugin

        class ContentTypeHandler < Seahorse::Client::Handler
          def call(context)
            body = context.http_request.body
            # Rest::Handler will set a default JSON body, so size can be checked
            # if this handler is run after serialization.
            if !body.respond_to?(:size) ||
               (body.respond_to?(:size) && body.size > 0)
              context.http_request.headers['Content-Type'] ||=
                'application/json'
            end
            @handler.call(context)
          end
        end

        handler(Rest::Handler)
        handler(ContentTypeHandler, priority: 30)
        handler(Json::ErrorHandler, step: :sign)
      end

    end
  end
end
