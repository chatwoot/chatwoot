# frozen_string_literal: true

require "logger"
require "fileutils"
require "tidewave/configuration"
require "tidewave/middleware"
require "tidewave/exceptions_middleware"

gem_tools_path = File.expand_path("tools/**/*.rb", __dir__)
Dir[gem_tools_path].each { |f| require f }

module Tidewave
  class Railtie < Rails::Railtie
    config.tidewave = Tidewave::Configuration.new()

    initializer "tidewave.setup" do |app|
      unless app.config.enable_reloading
        raise "For security reasons, Tidewave is only supported in environments where config.enable_reloading is true (typically development)"
      end

      app.config.middleware.insert_after(
        ActionDispatch::Callbacks,
        Tidewave::Middleware,
        app.config.tidewave
      )

      app.config.after_initialize do
        # If the user configured CSP, we need to alter it in dev
        # to allow TC to run browser_eval.
        app.config.content_security_policy.try do |content_security_policy|
          content_security_policy.directives["script-src"].try do |script_src|
            script_src << "'unsafe-eval'" unless script_src.include?("'unsafe-eval'")
          end
        end
      end
    end

    initializer "tidewave.intercept_exceptions" do |app|
      # We intercept exceptions from DebugExceptions, format the
      # information as text and inject into the exception page html.

      ActionDispatch::DebugExceptions.register_interceptor do |request, exception|
        request.set_header("tidewave.exception", exception)
      end

      app.middleware.insert_before(ActionDispatch::DebugExceptions, Tidewave::ExceptionsMiddleware)
    end
  end
end
