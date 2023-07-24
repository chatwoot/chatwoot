if ActiveModel::Type::Boolean.new.cast(ENV.fetch('LOGRAGE_ENABLED', false)).present?
  require 'lograge'

  Rails.application.configure do
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_payload do |controller|
      # Fixes https://github.com/chatwoot/chatwoot/issues/6922
      user_id = controller.try(:current_user).try(:id) unless controller.is_a?(SuperAdmin::Devise::SessionsController)
      {
        host: controller.request.host,
        remote_ip: controller.request.remote_ip,
        user_id: user_id
      }
    end

    config.lograge.custom_options = lambda do |event|
      param_exceptions = %w[controller action format id]
      {
        params: event.payload[:params]&.except(*param_exceptions)
      }
    end

    config.lograge.ignore_custom = lambda do |event|
      # ignore update_presence  events in log
      return true if event.payload[:channel_class] == 'RoomChannel'
    end
  end
end
