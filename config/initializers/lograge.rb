Rails.application.configure do
 
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = true
  config.lograge.formatter =  Lograge::Formatters::Json.new
  config.colorize_logging = false
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host,
      user_id: controller.current_user.try(:id)
    }
  end

  config.lograge.custom_options = lambda do |event|
    { 
      :level => event.payload[:level]
    }
  end

  config.lograge.ignore_custom = lambda do |event|
    #ignore update_presence  events in log
    if event.payload[:channel_class] == "RoomChannel"
        return true
    end
  end

end

