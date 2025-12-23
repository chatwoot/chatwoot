# frozen_string_literal: true

require "rails/railtie"
require_relative "action_controller"
require_relative "middleware/context/additions"

module Browser
  class Railtie < Rails::Railtie
    config.browser = ActiveSupport::OrderedOptions.new

    initializer "browser" do
      ActiveSupport.on_load(:action_controller) do
        ::ActionController::Base.include(Browser::ActionController)

        ::ActionController::Metal.include(Browser::ActionController) if defined?(::ActionController::Metal) # rubocop:disable Layout/LineLength

        Browser::Middleware::Context.include(
          Browser::Middleware::Context::Additions
        )
      end
    end
  end
end
