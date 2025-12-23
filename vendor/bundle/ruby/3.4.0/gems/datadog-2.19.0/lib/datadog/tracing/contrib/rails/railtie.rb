# frozen_string_literal: true

require_relative 'framework'
require_relative 'middlewares'
require_relative '../rack/middlewares'

module Datadog
  # Railtie class initializes
  class Railtie < Rails::Railtie
    # Add the trace middleware to the application stack
    initializer 'datadog.before_initialize' do |app|
      Tracing::Contrib::Rails::Patcher.before_initialize(app)
    end

    config.after_initialize do
      Tracing::Contrib::Rails::Patcher.after_initialize(self)
    end
  end
end
