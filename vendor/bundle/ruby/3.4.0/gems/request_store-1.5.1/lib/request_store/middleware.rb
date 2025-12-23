require 'rack/body_proxy'

# A middleware that ensures the RequestStore stays around until
# the last part of the body is rendered. This is useful when
# using streaming.
#
# Uses Rack::BodyProxy, adapted from Rack::Lock's usage of the
# same pattern.

module RequestStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      RequestStore.begin!

      status, headers, body = @app.call(env)

      body = Rack::BodyProxy.new(body) do
        RequestStore.end!
        RequestStore.clear!
      end
      
      returned = true

      [status, headers, body]
    ensure
      unless returned
        RequestStore.end!
        RequestStore.clear!
      end
    end
  end
end
