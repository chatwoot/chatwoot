require "rails"
require "sentry-ruby"
require "sentry/integrable"
require "sentry/rails/tracing"
require "sentry/rails/configuration"
require "sentry/rails/engine"
require "sentry/rails/railtie"

module Sentry
  module Rails
    extend Integrable
    register_integration name: "rails", version: Sentry::Rails::VERSION
  end
end
