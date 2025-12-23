require_relative "base"

class Rack::Timeout::Railtie < Rails::Railtie
  initializer("rack-timeout.prepend") do |app|
    next if Rails.env.test?

    if defined?(ActionDispatch::RequestId)
      app.config.middleware.insert_after(ActionDispatch::RequestId, Rack::Timeout)
    else
      app.config.middleware.insert_before(Rack::Runtime, Rack::Timeout)
    end
  end
end