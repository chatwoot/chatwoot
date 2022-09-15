Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host,
      remote_ip: controller.request.remote_ip,
      user_id: controller.current_user.try(:id)
    }
  end

  config.lograge.custom_options = lambda do |event|
    {
      level: event.payload[:level]
    }
  end

  config.lograge.ignore_custom = lambda do |event|
    # ignore update_presence  events in log
    return true if event.payload[:channel_class] == 'RoomChannel'
  end
end
