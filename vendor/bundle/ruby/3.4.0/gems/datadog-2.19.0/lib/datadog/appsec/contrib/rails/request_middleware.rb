# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Rails
        # Rack middleware for AppSec on Rails
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
