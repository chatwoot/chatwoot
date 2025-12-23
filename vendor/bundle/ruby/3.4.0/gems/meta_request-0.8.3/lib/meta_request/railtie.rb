# frozen_string_literal: true

require 'rails/railtie'

module MetaRequest
  class Railtie < ::Rails::Railtie
    initializer 'meta_request.inject_middlewares' do |app|
      app.middleware.use Middlewares::MetaRequestHandler

      if defined? ActionDispatch::DebugExceptions
        app.middleware.insert_before ActionDispatch::DebugExceptions, Middlewares::Headers, app.config
      else
        app.middleware.use Middlewares::Headers, app.config
      end

      app.middleware.use Middlewares::AppRequestHandler
    end

    initializer 'meta_request.log_interceptor' do
      Rails.logger&.extend(LogInterceptor)
    end

    initializer 'meta_request.subscribe_to_notifications' do
      AppNotifications.subscribe
    end
  end
end
