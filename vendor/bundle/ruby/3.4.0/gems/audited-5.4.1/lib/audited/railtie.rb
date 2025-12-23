# frozen_string_literal: true

module Audited
  class Railtie < Rails::Railtie
    initializer "audited.sweeper" do
      ActiveSupport.on_load(:action_controller) do
        if defined?(ActionController::Base)
          ActionController::Base.around_action Audited::Sweeper.new
        end
        if defined?(ActionController::API)
          ActionController::API.around_action Audited::Sweeper.new
        end
      end
    end
  end
end
