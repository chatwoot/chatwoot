# frozen_string_literal: true

require 'rails/railtie'
require 'action_view/log_subscriber'
require 'action_controller/log_subscriber'

module Lograge
  class Railtie < Rails::Railtie
    config.lograge = Lograge::OrderedOptions.new
    config.lograge.enabled = false

    initializer :deprecator do |app|
      app.deprecators[:lograge] = Lograge.deprecator if app.respond_to?(:deprecators)
    end

    config.after_initialize do |app|
      Lograge.setup(app) if app.config.lograge.enabled
    end
  end
end
