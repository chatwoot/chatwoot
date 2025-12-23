# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Sinatra
        # Rack middleware for AppSec on Sinatra
        class RequestMiddleware
          def initialize(app, opt = {})
            @app = app
          end

          def call(env)
            @app.call(env)
          end
        end
      end
    end
  end
end
