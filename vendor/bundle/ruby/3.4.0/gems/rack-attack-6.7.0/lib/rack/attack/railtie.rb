# frozen_string_literal: true

begin
  require 'rails/railtie'
rescue LoadError
  return
end

module Rack
  class Attack
    class Railtie < ::Rails::Railtie
      initializer "rack-attack.middleware" do |app|
        app.middleware.use(Rack::Attack)
      end
    end
  end
end
